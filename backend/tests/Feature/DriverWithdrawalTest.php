<?php

namespace Tests\Feature;

use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DriverWithdrawalTest extends TestCase
{
    use RefreshDatabase;

    public function test_driver_can_request_withdrawal_and_amount_is_reserved(): void
    {
        $driver = User::factory()->create(['role' => 'driver', 'wallet_balance' => 100]);
        Sanctum::actingAs($driver, ['driver']);

        $this->postJson('api/drivers/me/withdrawals', [
            'amount' => 60,
            'method' => 'mobile_wallet',
            'account_name' => 'Driver Name',
            'account_number' => '0599000000',
        ])->assertCreated()->assertJsonPath('wallet_balance', 40);

        $this->assertSame('40.00', $driver->fresh()->wallet_balance);
        $this->assertDatabaseHas('driver_withdrawals', ['driver_id' => $driver->id, 'amount' => 60, 'status' => 'pending']);
    }

    public function test_driver_cannot_withdraw_more_than_available_balance(): void
    {
        $driver = User::factory()->create(['role' => 'driver', 'wallet_balance' => 20]);
        Sanctum::actingAs($driver, ['driver']);

        $this->postJson('api/drivers/me/withdrawals', [
            'amount' => 30,
            'method' => 'bank',
            'account_name' => 'Driver Name',
            'account_number' => '123456',
        ])->assertUnprocessable();

        $this->assertSame('20.00', $driver->fresh()->wallet_balance);
    }

    public function test_the_drivers_ledger_accounts_for_every_change_to_the_balance(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $customer = User::factory()->create(['role' => 'customer', 'wallet_balance' => 100]);
        $driver = User::factory()->create(['role' => 'driver', 'wallet_balance' => 0]);

        // +85: earnings from a 100 ride after the 15% commission.
        $ride = RideRequest::create([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 100,
            'pickup_address' => 'نقطة الانطلاق',
            'pickup_lat' => 0,
            'pickup_lng' => 0,
            'dropoff_address' => 'الوجهة',
            'dropoff_lat' => 0,
            'dropoff_lng' => 0,
            'requested_at' => now(),
        ]);
        Sanctum::actingAs($driver, ['driver']);
        $this->patchJson("api/rides/{$ride->id}", ['status' => 'trip_completed'])->assertOk();

        // -30 held for a withdrawal, then -20 held and returned on rejection.
        $this->postJson('api/drivers/me/withdrawals', $this->withdrawal(30))->assertCreated();
        $rejectedId = $this->postJson('api/drivers/me/withdrawals', $this->withdrawal(20))
            ->assertCreated()
            ->json('withdrawal.id');
        $this->actingAs($admin)
            ->patch("/admin/driver-withdrawals/{$rejectedId}/reject")
            ->assertRedirect();

        $balance = (float) $driver->fresh()->wallet_balance;
        $this->assertSame(55.0, $balance);

        $ledger = WalletTransaction::query()->where('user_id', $driver->id)->orderByDesc('id')->get();
        $this->assertSame(
            ['withdrawal_return', 'withdrawal_hold', 'withdrawal_hold', 'driver_earning_credit'],
            $ledger->pluck('type')->all(),
            'One entry per change to the driver\'s balance, newest first.',
        );
        $this->assertEqualsWithDelta(
            $balance,
            $ledger->sum(fn (WalletTransaction $entry) => (float) $entry->amount),
            0.001,
            'The entries must add up to the balance, leaving no money unexplained.',
        );
        $this->assertEqualsWithDelta($balance, (float) $ledger->first()->balance_after, 0.001);
    }

    /** @return array<string, mixed> */
    private function withdrawal(float $amount): array
    {
        return [
            'amount' => $amount,
            'method' => 'mobile_wallet',
            'account_name' => 'Driver Name',
            'account_number' => '123456',
        ];
    }
}
