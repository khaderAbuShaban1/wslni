<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleIdTokenVerifier;
use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class GoogleSignInTest extends TestCase
{
    use RefreshDatabase;

    private const CLIENT_ID = 'web-client.apps.googleusercontent.com';

    /** @var array{sub: string, email: string, name: ?string, picture: ?string} */
    private array $claims = [
        'sub' => 'google-sub-1',
        'email' => 'sara@example.com',
        'name' => 'Sara',
        'picture' => null,
    ];

    protected function setUp(): void
    {
        parent::setUp();

        $test = $this;
        $this->app->instance(GoogleIdTokenVerifier::class, new class($test) extends GoogleIdTokenVerifier
        {
            public function __construct(private GoogleSignInTest $test) {}

            public function verify(string $idToken): array
            {
                if ($idToken === 'bad') {
                    throw new RuntimeException('bad');
                }

                return $this->test->claims();
            }
        });
    }

    public function claims(): array
    {
        return $this->claims;
    }

    public function test_new_customer_is_created_verified_and_signed_in(): void
    {
        $response = $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'customer']);

        $response->assertOk()->assertJsonPath('user.email', 'sara@example.com');
        $this->assertNotEmpty($response->json('token'));
        $user = User::where('email', 'sara@example.com')->firstOrFail();
        $this->assertSame('customer', $user->role);
        $this->assertSame('google-sub-1', $user->google_id);
        $this->assertNotNull($user->email_verified_at);
        $this->assertNull($user->phone);
    }

    public function test_existing_unverified_account_is_linked_and_verified(): void
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'email' => 'sara@example.com',
            'email_verified_at' => null,
        ]);

        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'customer'])->assertOk();

        $user->refresh();
        $this->assertSame('google-sub-1', $user->google_id);
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame(1, User::count());
    }

    public function test_drivers_cannot_sign_up_through_google(): void
    {
        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'driver'])->assertNotFound();

        $this->assertSame(0, User::count());
    }

    public function test_existing_driver_signs_in_through_the_driver_app(): void
    {
        User::factory()->create(['role' => 'driver', 'email' => 'sara@example.com']);

        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'driver'])
            ->assertOk()
            ->assertJsonPath('user.role', 'driver');
    }

    public function test_account_role_must_match_the_app(): void
    {
        User::factory()->create(['role' => 'customer', 'email' => 'sara@example.com']);

        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'driver'])->assertForbidden();
    }

    public function test_email_linked_to_another_google_account_is_refused(): void
    {
        User::factory()->create([
            'role' => 'customer',
            'email' => 'sara@example.com',
            'google_id' => 'someone-else',
        ]);

        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'customer'])->assertStatus(409);
    }

    public function test_suspended_accounts_are_refused(): void
    {
        User::factory()->create([
            'role' => 'customer',
            'email' => 'sara@example.com',
            'account_status' => 'suspended',
        ]);

        $this->postJson('api/auth/google', ['id_token' => 'ok', 'role' => 'customer'])->assertForbidden();
    }

    public function test_invalid_token_is_rejected(): void
    {
        $this->postJson('api/auth/google', ['id_token' => 'bad', 'role' => 'customer'])->assertUnauthorized();

        $this->assertSame(0, User::count());
    }

    public function test_verifier_accepts_only_tokens_for_this_app(): void
    {
        config(['services.google.client_ids' => [self::CLIENT_ID]]);
        Cache::forget('google.oauth.certs');

        $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $details = openssl_pkey_get_details($key);
        openssl_pkey_export($key, $privatePem);
        $b64 = fn (string $bin) => rtrim(strtr(base64_encode($bin), '+/', '-_'), '=');
        Http::fake(['www.googleapis.com/*' => Http::response(['keys' => [[
            'kty' => 'RSA', 'alg' => 'RS256', 'use' => 'sig', 'kid' => 'k1',
            'n' => $b64($details['rsa']['n']), 'e' => $b64($details['rsa']['e']),
        ]]])]);

        $sign = fn (array $overrides) => JWT::encode(array_merge([
            'iss' => 'https://accounts.google.com',
            'aud' => self::CLIENT_ID,
            'sub' => '123',
            'email' => 'Sara@Example.com',
            'email_verified' => true,
            'iat' => time(),
            'exp' => time() + 600,
        ], $overrides), $privatePem, 'RS256', 'k1');

        $verifier = new GoogleIdTokenVerifier;
        $this->assertSame('sara@example.com', $verifier->verify($sign([]))['email']);

        foreach ([
            'other app' => ['aud' => 'someone-else.apps.googleusercontent.com'],
            'unverified email' => ['email_verified' => false],
            'wrong issuer' => ['iss' => 'https://evil.example.com'],
            'expired' => ['exp' => time() - 3600],
        ] as $case => $overrides) {
            try {
                $verifier->verify($sign($overrides));
                $this->fail("Token with {$case} was accepted.");
            } catch (RuntimeException) {
                $this->addToAssertionCount(1);
            }
        }
    }
}
