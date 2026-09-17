<?php

namespace Tests\Feature;

use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * A cancelled ride must leave nobody paid: no fare on the record, no
 * commission, and anything a settled ride already moved returned.
 */
class RideCancellationRefundTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_cancelling_a_settled_ride_refunds_the_customer_and_reverses_driver_earnings(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 85);

        // A completed ride: 100 fare already charged, 15% commission taken,
        // so the driver was credited 85.
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_completed',
            'actual_fare' => 100,
            'platform_fee' => 15,
            'commission_percent' => 15,
            'completed_at' => now(),
        ]);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled'])
            ->assertRedirect();

        $this->assertSame(200.0, (float) $customer->fresh()->wallet_balance, 'Customer must get the fare back.');
        $this->assertSame(0.0, (float) $driver->fresh()->wallet_balance, 'Driver earnings must be reversed.');

        $ride->refresh();
        $this->assertSame('cancelled', $ride->status);
        $this->assertNull($ride->actual_fare);
        $this->assertNull($ride->platform_fee);
        $this->assertNull($ride->completed_at);

        $this->assertDatabaseHas('wallet_transactions', [
            'ride_request_id' => $ride->id,
            'type' => 'ride_fare_refund',
        ]);
        $this->assertDatabaseHas('wallet_transactions', [
            'ride_request_id' => $ride->id,
            'type' => 'platform_commission_reversal',
        ]);
    }

    public function test_admin_cancelling_an_unsettled_ride_writes_no_commission(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 0);

        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
            'actual_fare' => 60,
            'fare_estimate' => 60,
        ]);

        // The admin form posts the fare alongside the status; the old code
        // turned that into a commission even while cancelling.
        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", [
                'status' => 'cancelled',
                'actual_fare' => 60,
            ])
            ->assertRedirect();

        $ride->refresh();
        $this->assertNull($ride->platform_fee, 'Cancelling must never record a commission.');
        $this->assertNull($ride->actual_fare);
        $this->assertSame(100.0, (float) $customer->fresh()->wallet_balance, 'No money moves on an unsettled cancel.');
    }

    public function test_driver_cancelling_clears_the_agreed_fare(): void
    {
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 0);

        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
            'actual_fare' => 45,
        ]);

        Sanctum::actingAs($driver, ['driver']);
        $this->patchJson("api/rides/{$ride->id}", ['status' => 'cancelled'])->assertOk();

        $ride->refresh();
        $this->assertSame('cancelled', $ride->status);
        $this->assertNull($ride->actual_fare);
        $this->assertNull($ride->platform_fee);
        $this->assertSame(100.0, (float) $customer->fresh()->wallet_balance);
    }

    private function user(string $role, float $balance): User
    {
        static $sequence = 0;
        $sequence++;

        return User::create([
            'name' => "{$role}-{$sequence}",
            'email' => "{$role}{$sequence}@example.test",
            'phone' => '05970010'.str_pad((string) $sequence, 2, '0', STR_PAD_LEFT),
            'password' => Hash::make('123123123'),
            'role' => $role,
            'account_status' => 'active',
            'wallet_balance' => $balance,
            'email_verified_at' => now(),
        ]);
    }

    private function ride(User $customer, array $attributes): RideRequest
    {
        return RideRequest::create(array_merge([
            'customer_id' => $customer->id,
            'pickup_address' => 'نقطة الانطلاق',
            'pickup_lat' => 0,
            'pickup_lng' => 0,
            'dropoff_address' => 'الوجهة',
            'dropoff_lat' => 0,
            'dropoff_lng' => 0,
            'requested_at' => now(),
        ], $attributes));
    }
}
