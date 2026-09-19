<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // The per-email auth limiter would otherwise cut these flows short.
        $this->withoutMiddleware(ThrottleRequests::class);
    }

    public function test_unknown_email_gets_the_same_answer_and_no_code(): void
    {
        $known = User::factory()->create(['email' => 'known@example.com']);

        $unknown = $this->postJson('api/auth/forgot-password', ['email' => 'nobody@example.com'])->assertOk();
        $existing = $this->postJson('api/auth/forgot-password', ['email' => $known->email])->assertOk();

        $this->assertSame($existing->json('message'), $unknown->json('message'));
        $this->assertDatabaseMissing('password_reset_codes', ['email' => 'nobody@example.com']);
        $this->assertDatabaseHas('password_reset_codes', ['email' => 'known@example.com']);
    }

    public function test_resending_within_a_minute_keeps_the_same_code(): void
    {
        User::factory()->create(['email' => 'a@example.com']);

        $this->postJson('api/auth/forgot-password', ['email' => 'a@example.com']);
        $first = DB::table('password_reset_codes')->value('code_hash');
        $this->postJson('api/auth/forgot-password', ['email' => 'a@example.com']);

        $this->assertSame($first, DB::table('password_reset_codes')->value('code_hash'));
    }

    public function test_full_flow_changes_the_password_and_signs_out_everywhere(): void
    {
        $user = User::factory()->create(['email' => 'a@example.com', 'password' => 'old-password']);
        $user->createToken('phone');
        $this->seedCode('a@example.com', '123456');

        $token = $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '123456'])
            ->assertOk()
            ->json('reset_token');

        $this->postJson('api/auth/reset-password', [
            'email' => 'a@example.com',
            'reset_token' => $token,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk();

        $user->refresh();
        $this->assertTrue(Hash::check('new-password', $user->password));
        $this->assertSame(0, $user->tokens()->count());
        $this->assertDatabaseCount('password_reset_codes', 0);
    }

    public function test_code_works_only_once(): void
    {
        User::factory()->create(['email' => 'a@example.com']);
        $this->seedCode('a@example.com', '123456');

        $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '123456'])->assertOk();
        $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '123456'])
            ->assertUnprocessable();
    }

    public function test_five_wrong_codes_burn_the_code(): void
    {
        User::factory()->create(['email' => 'a@example.com']);
        $this->seedCode('a@example.com', '123456');

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '000000'])
                ->assertUnprocessable();
        }

        $this->assertDatabaseCount('password_reset_codes', 0);
        $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '123456'])
            ->assertUnprocessable();
    }

    public function test_expired_code_is_rejected(): void
    {
        User::factory()->create(['email' => 'a@example.com']);
        $this->seedCode('a@example.com', '123456', expiresAt: now()->subMinute());

        $this->postJson('api/auth/forgot-password/verify', ['email' => 'a@example.com', 'code' => '123456'])
            ->assertUnprocessable();
    }

    public function test_reset_needs_the_token_from_verification(): void
    {
        $user = User::factory()->create(['email' => 'a@example.com', 'password' => 'old-password']);
        $this->seedCode('a@example.com', '123456');

        $this->postJson('api/auth/reset-password', [
            'email' => 'a@example.com',
            'reset_token' => str_repeat('x', 64),
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertUnprocessable();

        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    private function seedCode(string $email, string $code, $expiresAt = null): void
    {
        DB::table('password_reset_codes')->insert([
            'email' => $email,
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'code_expires_at' => $expiresAt ?? now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
