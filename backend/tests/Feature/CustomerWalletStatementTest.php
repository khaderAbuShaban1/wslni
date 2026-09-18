<?php

namespace Tests\Feature;

use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletDeposit;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The wallet statement must let a customer see where their money went: one
 * entry for every change to the balance, adding up to the balance itself.
 */
class CustomerWalletStatementTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_statement_accounts_for_every_change_to_the_balance(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 0);
        $driver = $this->user('driver', 0);

        // +200: a deposit the admin approves.
        $deposit = WalletDeposit::create([
            'user_id' => $customer->id,
            'amount' => 200,
            'bank_name' => 'Bank of Palestine',
            'reference_number' => 'STATEMENT-1',
            'status' => 'pending',
        ]);
        $this->actingAs($admin)
            ->patch(route('admin.wallets.approve', $deposit), ['approved_amount' => 200])
            ->assertSessionHasNoErrors();

        // -60: a ride the driver completes.
        $ride = RideRequest::create([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 60,
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

        // -50 held for a withdrawal, then -30 held and returned on rejection.
        Sanctum::actingAs($customer, ['customer']);
        $this->postJson('api/customers/me/withdrawals', $this->withdrawal(50))->assertCreated();
        $rejectedId = $this->postJson('api/customers/me/withdrawals', $this->withdrawal(30))
            ->assertCreated()
            ->json('withdrawal.id');
        $this->actingAs($admin)
            ->patch("/admin/customer-withdrawals/{$rejectedId}/reject")
            ->assertRedirect();

        $balance = (float) $customer->fresh()->wallet_balance;
        $this->assertSame(90.0, $balance);

        Sanctum::actingAs($customer, ['customer']);
        $statement = $this->getJson('api/customers/me/wallet')->assertOk()->json('transactions');

        $this->assertSame(
            ['withdrawal_return', 'withdrawal_hold', 'withdrawal_hold', 'ride_fare_debit', 'deposit_credit'],
            array_column($statement, 'type'),
            'One entry per change, newest first, and only the customer\'s own.',
        );
        $this->assertEqualsWithDelta(
            $balance,
            array_sum(array_column($statement, 'amount')),
            0.001,
            'The entries must add up to the balance, leaving no money unexplained.',
        );
        $this->assertEqualsWithDelta($balance, $statement[0]['balance_after'], 0.001);
    }

    /** @return array<string, mixed> */
    private function withdrawal(float $amount): array
    {
        return [
            'amount' => $amount,
            'method' => 'mobile_wallet',
            'account_name' => 'زبون',
            'account_number' => '0599000111',
        ];
    }

    private function user(string $role, float $balance): User
    {
        static $sequence = 0;
        $sequence++;

        return User::create([
            'name' => "{$role}-{$sequence}",
            'email' => "{$role}{$sequence}@statement.test",
            'phone' => '05972220'.str_pad((string) $sequence, 2, '0', STR_PAD_LEFT),
            'password' => Hash::make('123123123'),
            'role' => $role,
            'account_status' => 'active',
            'wallet_balance' => $balance,
            'email_verified_at' => now(),
        ]);
    }
}
