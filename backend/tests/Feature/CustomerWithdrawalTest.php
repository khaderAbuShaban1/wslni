<?php

namespace Tests\Feature;

use App\Models\CustomerWithdrawal;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CustomerWithdrawalTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_request_a_withdrawal_and_the_amount_is_reserved(): void
    {
        $customer = $this->user('customer', 120);

        Sanctum::actingAs($customer, ['customer']);

        $this->postJson('api/customers/me/withdrawals', [
            'amount' => 50,
            'method' => 'mobile_wallet',
            'account_name' => 'تحسين',
            'account_number' => '0599000111',
        ])->assertCreated();

        $this->assertSame(
            70.0,
            (float) $customer->fresh()->wallet_balance,
            'The requested amount must be held while the admin reviews it.',
        );
        $this->assertDatabaseHas('customer_withdrawals', [
            'customer_id' => $customer->id,
            'amount' => 50.00,
            'status' => 'pending',
        ]);
    }

    public function test_customer_cannot_withdraw_more_than_the_balance(): void
    {
        $customer = $this->user('customer', 30);

        Sanctum::actingAs($customer, ['customer']);

        $this->postJson('api/customers/me/withdrawals', [
            'amount' => 31,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '123456',
        ])->assertStatus(422);

        $this->assertSame(30.0, (float) $customer->fresh()->wallet_balance);
        $this->assertDatabaseCount('customer_withdrawals', 0);
    }

    public function test_a_driver_cannot_use_the_customer_withdrawal_endpoint(): void
    {
        $driver = $this->user('driver', 100);

        Sanctum::actingAs($driver, ['driver']);

        $this->postJson('api/customers/me/withdrawals', [
            'amount' => 10,
            'method' => 'bank',
            'account_name' => 'سائق',
            'account_number' => '123456',
        ])->assertForbidden();
    }

    public function test_rejecting_a_withdrawal_returns_the_money(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 70);
        $withdrawal = CustomerWithdrawal::create([
            'customer_id' => $customer->id,
            'amount' => 50,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '123456',
            'status' => 'pending',
        ]);

        $this->actingAs($admin)
            ->patch("/admin/customer-withdrawals/{$withdrawal->id}/reject")
            ->assertRedirect();

        $this->assertSame(120.0, (float) $customer->fresh()->wallet_balance);
        $this->assertSame('rejected', $withdrawal->fresh()->status);
    }

    public function test_a_reviewed_withdrawal_cannot_be_rejected_twice(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->user('customer', 70);
        $withdrawal = CustomerWithdrawal::create([
            'customer_id' => $customer->id,
            'amount' => 50,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '123456',
            'status' => 'paid',
        ]);

        $this->actingAs($admin)
            ->patch("/admin/customer-withdrawals/{$withdrawal->id}/reject")
            ->assertRedirect();

        $this->assertSame(
            70.0,
            (float) $customer->fresh()->wallet_balance,
            'An already paid withdrawal must not be refunded.',
        );
    }

    public function test_the_wallet_lists_only_the_customers_own_withdrawals(): void
    {
        $customer = $this->user('customer', 60);
        $other = $this->user('customer', 60);

        CustomerWithdrawal::create([
            'customer_id' => $customer->id,
            'amount' => 25,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '111',
            'status' => 'paid',
        ]);
        CustomerWithdrawal::create([
            'customer_id' => $other->id,
            'amount' => 99,
            'method' => 'bank',
            'account_name' => 'آخر',
            'account_number' => '222',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->getJson('api/customers/me/wallet')
            ->assertOk()
            ->assertJsonCount(1, 'withdrawals')
            ->assertJsonPath('withdrawals.0.amount', 25)
            ->assertJsonPath('withdrawals.0.status', 'paid')
            ->assertJsonMissing(['account_number' => '222']);
    }

    public function test_the_customer_is_notified_when_the_withdrawal_is_paid(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->withDevice($this->user('customer', 70));
        $withdrawal = $this->pendingWithdrawal($customer);

        $messages = $this->captureNotifications();

        $this->actingAs($admin)
            ->patch("/admin/customer-withdrawals/{$withdrawal->id}/approve")
            ->assertRedirect();

        $this->assertArrayHasKey($customer->id, $messages, 'The customer must be told the money was sent.');
        $this->assertStringContainsString('تحويل', $messages[$customer->id]);
    }

    public function test_the_customer_is_notified_when_the_withdrawal_is_rejected(): void
    {
        $admin = $this->user('admin', 0);
        $customer = $this->withDevice($this->user('customer', 70));
        $withdrawal = $this->pendingWithdrawal($customer);

        $messages = $this->captureNotifications();

        $this->actingAs($admin)
            ->patch("/admin/customer-withdrawals/{$withdrawal->id}/reject")
            ->assertRedirect();

        $this->assertArrayHasKey($customer->id, $messages);
        $this->assertStringContainsString('رفض', $messages[$customer->id]);
    }

    public function test_requesting_a_withdrawal_sends_no_notification(): void
    {
        $customer = $this->withDevice($this->user('customer', 70));
        $messages = $this->captureNotifications();

        Sanctum::actingAs($customer, ['customer']);
        $this->postJson('api/customers/me/withdrawals', [
            'amount' => 20,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '123',
        ])->assertCreated();

        $this->assertCount(0, $messages, 'Only the admin decision should notify, not the request itself.');
    }

    private function withDevice(User $user): User
    {
        $user->update(['fcm_token' => "device-{$user->id}"]);

        return $user;
    }

    private function pendingWithdrawal(User $customer): CustomerWithdrawal
    {
        return CustomerWithdrawal::create([
            'customer_id' => $customer->id,
            'amount' => 50,
            'method' => 'bank',
            'account_name' => 'تحسين',
            'account_number' => '123456',
            'status' => 'pending',
        ]);
    }

    /** @return \ArrayObject<int, string> recipient id => body, shared so it fills during the request */
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

    private function user(string $role, float $balance): User
    {
        static $sequence = 0;
        $sequence++;

        return User::create([
            'name' => "{$role}-{$sequence}",
            'email' => "{$role}{$sequence}@example.test",
            'phone' => '05971110'.str_pad((string) $sequence, 2, '0', STR_PAD_LEFT),
            'password' => Hash::make('123123123'),
            'role' => $role,
            'account_status' => 'active',
            'wallet_balance' => $balance,
            'email_verified_at' => now(),
        ]);
    }
}
