<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WalletDeposit;
use App\Models\WalletPaymentAccount;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CustomerWalletTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_view_payment_accounts_and_submit_deposit(): void
    {
        Storage::fake('local');

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

        $this->getJson('api/customers/me/wallet')->assertUnauthorized();
        $this->getJson("api/customers/{$customer->id}/wallet")->assertNotFound();

        Sanctum::actingAs($customer, ['customer']);

        $this->getJson('api/customers/me/wallet')
            ->assertOk()
            ->assertJsonPath('wallet_balance', 12)
            ->assertJsonPath('payment_accounts.0.name', 'Bank of Palestine')
            ->assertJsonPath('payment_accounts.0.invoice_number', $account->invoiceNumber())
            ->assertJsonMissing(['name' => 'Inactive Wallet']);

        $this->post('api/customers/me/wallet/deposits', [
            'amount' => 50,
            'wallet_payment_account_id' => $account->id,
            'reference_number' => 'MOB-REF-1',
            'receipt_image' => UploadedFile::fake()->create('receipt.png', 8, 'image/png'),
        ], ['Accept' => 'application/json'])->assertCreated()
            ->assertJsonPath('deposit.status', 'pending');

        $deposit = WalletDeposit::query()->where('reference_number', 'MOB-REF-1')->first();

        $this->assertNotNull($deposit);
        $this->assertSame($account->id, $deposit->wallet_payment_account_id);
        Storage::disk('local')->assertExists($deposit->receipt_path);
        Storage::disk('public')->assertMissing($deposit->receipt_path);
        $this->assertNotNull($deposit->receipt_sha256);
    }

    public function test_driver_cannot_access_customer_wallet(): void
    {
        $driver = User::factory()->create([
            'role' => 'driver',
            'account_status' => 'active',
            'email_verified_at' => now(),
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->getJson('api/customers/me/wallet')->assertForbidden();
    }

    public function test_customer_profile_is_token_scoped(): void
    {
        $customer = User::factory()->create([
            'role' => 'customer',
            'account_status' => 'active',
            'email_verified_at' => now(),
            'wallet_balance' => 25,
        ]);

        $this->patchJson('api/customers/me', [
            'name' => 'Blocked update',
            'phone' => '0599000000',
        ])->assertUnauthorized();

        Sanctum::actingAs($customer, ['customer']);

        $this->patchJson('api/customers/me', [
            'name' => 'Updated Customer',
            'phone' => '0599111111',
        ])->assertOk()
            ->assertJsonPath('user.id', $customer->id)
            ->assertJsonPath('user.wallet_balance', 25);

        $this->patchJson("api/customers/{$customer->id}", [
            'name' => 'Legacy path',
            'phone' => '0599222222',
        ])->assertNotFound();
    }

    public function test_verified_customer_login_returns_a_scoped_token(): void
    {
        $customer = User::factory()->create([
            'email' => 'secure-wallet-login@example.com',
            'password' => Hash::make('strong-password'),
            'role' => 'customer',
            'account_status' => 'active',
            'email_verified_at' => now(),
        ]);

        $response = $this->postJson('api/auth/login', [
            'email' => $customer->email,
            'password' => 'strong-password',
        ])->assertOk()
            ->assertJsonPath('user.id', $customer->id)
            ->assertJsonStructure(['token']);

        $this->withToken($response->json('token'))
            ->getJson('api/customers/me/wallet')
            ->assertOk();
    }
}
