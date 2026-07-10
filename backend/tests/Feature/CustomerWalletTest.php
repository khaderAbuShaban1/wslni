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

class CustomerWalletTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_view_payment_accounts_and_submit_deposit(): void
    {
        Storage::fake('public');

        $customer = User::create([
            'name' => 'Customer User',
            'email' => 'customer-wallet@example.com',
            'phone' => '0597112001',
            'password' => Hash::make('123123123'),
            'role' => 'customer',
            'account_status' => 'active',
            'wallet_balance' => 12,
            'email_verified_at' => now(),
        ]);

        $account = WalletPaymentAccount::create([
            'type' => 'bank',
            'name' => 'Bank of Palestine',
            'account_holder_name' => 'Wslni',
            'account_number' => '123456789',
            'is_active' => true,
        ]);
        WalletPaymentAccount::create([
            'type' => 'mobile_wallet',
            'name' => 'Inactive Wallet',
            'account_holder_name' => 'Wslni',
            'phone_number' => '0599000000',
            'is_active' => false,
        ]);

        $this->getJson("api/customers/{$customer->id}/wallet")
            ->assertOk()
            ->assertJsonPath('wallet_balance', 12)
            ->assertJsonPath('payment_accounts.0.name', 'Bank of Palestine')
            ->assertJsonPath('payment_accounts.0.invoice_number', $account->invoiceNumber())
            ->assertJsonMissing(['name' => 'Inactive Wallet']);

        $this->post("api/customers/{$customer->id}/wallet/deposits", [
            'amount' => 50,
            'wallet_payment_account_id' => $account->id,
            'reference_number' => 'MOB-REF-1',
            'receipt_image' => UploadedFile::fake()->create('receipt.png', 8, 'image/png'),
        ], ['Accept' => 'application/json'])->assertCreated()
            ->assertJsonPath('deposit.status', 'pending');

        $deposit = WalletDeposit::query()->where('reference_number', 'MOB-REF-1')->first();

        $this->assertNotNull($deposit);
        $this->assertSame($account->id, $deposit->wallet_payment_account_id);
        Storage::disk('public')->assertExists($deposit->receipt_path);
    }
}
