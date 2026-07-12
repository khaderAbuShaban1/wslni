<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DriverWithdrawalTest extends TestCase
{
    use RefreshDatabase;

    public function test_driver_can_request_withdrawal_and_amount_is_reserved(): void
    {
        $driver = User::factory()->create(['role' => 'driver', 'wallet_balance' => 100]);

        $this->postJson("api/drivers/{$driver->id}/withdrawals", [
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

        $this->postJson("api/drivers/{$driver->id}/withdrawals", [
            'amount' => 30,
            'method' => 'bank',
            'account_name' => 'Driver Name',
            'account_number' => '123456',
        ])->assertUnprocessable();

        $this->assertSame('20.00', $driver->fresh()->wallet_balance);
    }
}
