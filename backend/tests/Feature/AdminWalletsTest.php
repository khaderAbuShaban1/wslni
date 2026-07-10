<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WalletDeposit;
use App\Models\WalletPaymentAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminWalletsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_and_approve_wallet_deposit(): void
    {
        Storage::fake('public');

        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'phone' => '0597111000',
            'password' => Hash::make('123123123'),
            'role' => 'admin',
            'account_status' => 'active',
            'wallet_balance' => 0,
            'email_verified_at' => now(),
        ]);

        $customer = User::create([
            'name' => 'Customer User',
            'email' => 'customer@example.com',
            'phone' => '0597111001',
            'password' => Hash::make('123123123'),
            'role' => 'customer',
            'account_status' => 'active',
            'wallet_balance' => 0,
            'email_verified_at' => now(),
        ]);

        $this->actingAs($admin)
            ->post(route('admin.wallets.store'), [
                'user_id' => $customer->id,
                'amount' => 75,
                'bank_name' => 'بنك فلسطين',
                'reference_number' => 'REF-TEST-001',
                'receipt_image' => UploadedFile::fake()->create('receipt.png', 120, 'image/png'),
                'note' => 'إشعار بنكي تجريبي',
            ])->assertRedirect();

        $deposit = WalletDeposit::query()->where('reference_number', 'REF-TEST-001')->first();

        $this->assertNotNull($deposit);
        $this->assertSame('pending', $deposit->status);
        $this->assertSame('0.00', $customer->fresh()->wallet_balance);

        $this->actingAs($admin)
            ->get(route('admin.wallets.index'))
            ->assertOk()
            ->assertSee('REF-TEST-001')
            ->assertSee('75.00');

        $this->actingAs($admin)
            ->patch(route('admin.wallets.approve', $deposit), [
                'approved_amount' => 50,
            ])
            ->assertRedirect();

        $this->assertSame('50.00', $customer->fresh()->wallet_balance);
        $this->assertSame('50.00', $deposit->fresh()->amount);
        $this->assertDatabaseHas('wallet_deposits', [
            'reference_number' => 'REF-TEST-001',
            'status' => 'approved',
        ]);
    }

    public function test_admin_can_create_and_toggle_wallet_payment_account(): void
    {
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin-payment@example.com',
            'phone' => '0597111002',
            'password' => Hash::make('123123123'),
            'role' => 'admin',
            'account_status' => 'active',
            'wallet_balance' => 0,
            'email_verified_at' => now(),
        ]);

        $this->actingAs($admin)
            ->post(route('admin.wallet-payment-accounts.store'), [
                'type' => 'mobile_wallet',
                'name' => 'Jawwal Pay',
                'account_holder_name' => 'Wslni',
                'phone_number' => '0599000000',
                'sort_order' => 1,
            ])->assertRedirect();

        $account = WalletPaymentAccount::query()->where('name', 'Jawwal Pay')->first();

        $this->assertNotNull($account);
        $this->assertTrue($account->is_active);

        $this->actingAs($admin)
            ->get(route('admin.wallet-payment-accounts.index'))
            ->assertOk()
            ->assertSee('Jawwal Pay');

        $this->actingAs($admin)
            ->patch(route('admin.wallet-payment-accounts.update', $account), [
                'type' => 'bank',
                'name' => 'Bank of Palestine',
                'account_holder_name' => 'Wslni Company',
                'account_number' => 'PS92PALS000000000000000000000',
                'phone_number' => null,
                'instructions' => 'Use the app receipt upload after transfer.',
                'sort_order' => 2,
                'is_active' => '1',
            ])->assertRedirect();

        $account->refresh();

        $this->assertSame('bank', $account->type);
        $this->assertSame('Bank of Palestine', $account->name);
        $this->assertSame(2, $account->sort_order);
        $this->assertTrue($account->is_active);

        $this->actingAs($admin)
            ->patch(route('admin.wallet-payment-accounts.toggle', $account))
            ->assertRedirect();

        $this->assertFalse($account->fresh()->is_active);
    }

    public function test_admin_can_extract_wallet_payment_account_invoice(): void
    {
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin-invoice@example.com',
            'phone' => '0597111003',
            'password' => Hash::make('123123123'),
            'role' => 'admin',
            'account_status' => 'active',
            'wallet_balance' => 0,
            'email_verified_at' => now(),
        ]);

        $customer = User::create([
            'name' => 'Customer User',
            'email' => 'customer-invoice@example.com',
            'phone' => '0597111004',
            'password' => Hash::make('123123123'),
            'role' => 'customer',
            'account_status' => 'active',
            'wallet_balance' => 0,
            'email_verified_at' => now(),
        ]);

        $account = WalletPaymentAccount::create([
            'type' => 'mobile_wallet',
            'name' => 'PalPay',
            'account_holder_name' => 'Wslni',
            'phone_number' => '0599000000',
            'is_active' => true,
        ]);

        WalletDeposit::create([
            'user_id' => $customer->id,
            'wallet_payment_account_id' => $account->id,
            'amount' => 60,
            'bank_name' => $account->name,
            'reference_number' => 'INV-REF-1',
            'status' => 'approved',
        ]);

        $this->actingAs($admin)
            ->get(route('admin.wallet-payment-accounts.invoice', $account))
            ->assertOk()
            ->assertSee('فاتورة طريقة دفع')
            ->assertSee($account->invoiceNumber())
            ->assertSee('INV-REF-1')
            ->assertSee('60.00');
    }
}
