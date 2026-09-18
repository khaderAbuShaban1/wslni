<?php

namespace Tests\Feature;

use App\Models\RideRequest;
use App\Models\User;
use App\Services\FcmService;
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
        $driver = $this->user('driver', 0);

        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
        ]);

        // Settle it the way the app does, so the charge is really recorded:
        // 100 taken from the customer, 15% commission, 85 to the driver.
        Sanctum::actingAs($driver, ['driver']);
        $this->patchJson("api/rides/{$ride->id}", ['status' => 'trip_completed'])->assertOk();
        $this->assertSame(0.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame(85.0, (float) $driver->fresh()->wallet_balance);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled'])
            ->assertRedirect();

        $this->assertSame(100.0, (float) $customer->fresh()->wallet_balance, 'Customer must get the fare back.');
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

    public function test_admin_cancellation_tells_both_sides_and_blames_neither(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 0, 'customer-device');
        $driver = $this->user('driver', 0, 'driver-device');

        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
        ]);

        $messages = $this->captureNotifications();

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled'])
            ->assertRedirect();

        $this->assertArrayHasKey($customer->id, $messages, 'The customer must be told.');
        $this->assertArrayHasKey($driver->id, $messages, 'The waiting driver must be told.');
        $this->assertStringNotContainsString(
            'السائق',
            $messages[$customer->id],
            'An admin cancellation must not be blamed on the driver.',
        );
    }

    public function test_driver_cancellation_is_attributed_to_the_driver(): void
    {
        $customer = $this->user('customer', 0, 'customer-device');
        $driver = $this->user('driver', 0, 'driver-device');

        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
        ]);

        $messages = $this->captureNotifications();

        Sanctum::actingAs($driver, ['driver']);
        $this->patchJson("api/rides/{$ride->id}", ['status' => 'cancelled'])->assertOk();

        $this->assertArrayHasKey($customer->id, $messages);
        $this->assertStringContainsString('السائق', $messages[$customer->id]);
    }

    /**
     * Recipient id => notification body. Returned as a shared object so it
     * keeps filling as the request runs; a plain array would be copied empty.
     *
     * @return \ArrayObject<int, string>
     */
    private function captureNotifications(): \ArrayObject
    {
        $messages = new \ArrayObject();

        $this->mock(FcmService::class, function ($mock) use ($messages) {
            $mock->shouldReceive('sendToUser')
                ->andReturnUsing(function (User $user, string $title, string $body) use ($messages) {
                    $messages[(int) $user->id] = $body;

                    return true;
                });
        });

        return $messages;
    }

    public function test_cancelling_a_completed_ride_with_no_recorded_charge_refunds_nothing(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 100);

        // Older rides reached completed without the charge being recorded.
        // Reversal follows the recorded money, so these must refund nothing.
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_completed',
            'actual_fare' => 60,
            'platform_fee' => 9,
            'completed_at' => now(),
        ]);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled'])
            ->assertRedirect();

        $this->assertSame(100.0, (float) $customer->fresh()->wallet_balance, 'Nothing was charged, so nothing may be refunded.');
        $this->assertSame(100.0, (float) $driver->fresh()->wallet_balance, 'Nothing was credited, so nothing may be taken back.');
        $this->assertDatabaseMissing('wallet_transactions', ['ride_request_id' => $ride->id, 'type' => 'ride_fare_refund']);
    }

    public function test_admin_completing_a_ride_charges_the_customer_and_pays_the_driver(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 0);
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
        ]);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'trip_completed'])
            ->assertSessionHasNoErrors();

        // The same figures the driver app produces for the same ride.
        $this->assertSame(0.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame(85.0, (float) $driver->fresh()->wallet_balance);

        $ride->refresh();
        $this->assertSame('trip_completed', $ride->status);
        $this->assertSame(15.0, (float) $ride->platform_fee);
        $this->assertNotNull($ride->completed_at);

        $this->assertDatabaseHas('wallet_transactions', ['ride_request_id' => $ride->id, 'type' => 'ride_fare_debit', 'amount' => -100, 'user_id' => $customer->id, 'created_by' => $admin->id]);
        $this->assertDatabaseHas('wallet_transactions', ['ride_request_id' => $ride->id, 'type' => 'driver_earning_credit', 'amount' => 85, 'user_id' => $driver->id]);
        $this->assertDatabaseHas('wallet_transactions', ['ride_request_id' => $ride->id, 'type' => 'platform_commission', 'amount' => 15]);
    }

    public function test_admin_completion_is_refused_when_the_customer_cannot_pay(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 50);
        $driver = $this->user('driver', 0);
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
        ]);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'trip_completed'])
            ->assertSessionHasErrors('status');

        $this->assertSame(50.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame(0.0, (float) $driver->fresh()->wallet_balance);
        $this->assertSame('trip_started', $ride->fresh()->status, 'A refused settlement must leave the ride as it was.');
        $this->assertDatabaseCount('wallet_transactions', 0);
    }

    public function test_the_admin_can_correct_the_fare_when_completing(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 0);
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
        ]);

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'trip_completed', 'actual_fare' => 40])
            ->assertSessionHasNoErrors();

        $this->assertSame(60.0, (float) $customer->fresh()->wallet_balance, 'The corrected fare is what gets charged.');
        $this->assertSame(34.0, (float) $driver->fresh()->wallet_balance);
    }

    public function test_a_ride_the_admin_completed_is_fully_reversed_when_cancelled(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 100);
        $driver = $this->user('driver', 0);
        $ride = $this->ride($customer, [
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
        ]);

        $this->actingAs($admin)->patch("/admin/rides/{$ride->id}/status", ['status' => 'trip_completed']);
        // The money must really have moved, or the reversal below proves nothing.
        $this->assertSame(0.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame(85.0, (float) $driver->fresh()->wallet_balance);

        $this->actingAs($admin)->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled']);

        $this->assertSame(100.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame(0.0, (float) $driver->fresh()->wallet_balance);
    }

    public function test_an_already_cancelled_ride_cannot_be_cancelled_again(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 0, 'customer-device');
        $ride = $this->ride($customer, ['status' => 'cancelled']);

        $messages = $this->captureNotifications();

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'cancelled'])
            ->assertSessionHasErrors('status');

        $this->assertCount(0, $messages, 'A second cancel must not notify the customer again.');
    }

    public function test_a_driverless_ride_cannot_enter_a_driver_stage(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 0, 'customer-device');
        $ride = $this->ride($customer, ['status' => 'receiving_offers']);

        $messages = $this->captureNotifications();

        $this->actingAs($admin)
            ->patch("/admin/rides/{$ride->id}/status", ['status' => 'driver_selected'])
            ->assertSessionHasErrors('status');

        $this->assertSame('receiving_offers', $ride->fresh()->status);
        $this->assertCount(0, $messages, 'No driver exists, so nobody may be told one is coming.');
    }

    public function test_an_expired_admin_session_redirects_to_login_instead_of_erroring(): void
    {
        $this->get('/admin/rides')->assertRedirect(route('auth.login'));
    }

    private function user(string $role, float $balance, ?string $fcmToken = null): User
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
            'fcm_token' => $fcmToken,
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
