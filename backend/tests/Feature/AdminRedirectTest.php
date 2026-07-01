<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminRedirectTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_user_is_redirected_from_home_to_admin_dashboard(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
        ]);

        $this->actingAs($admin)
            ->get('/home')
            ->assertRedirect(route('admin.dashboard'));
    }

    public function test_admin_login_redirects_to_admin_dashboard(): void
    {
        $password = 'Password123!';
        $admin = User::factory()->create([
            'role' => 'admin',
            'password' => Hash::make($password),
        ]);

        $this->post(route('auth.login.store'), [
            'email' => $admin->email,
            'password' => $password,
        ])->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticatedAs($admin);
    }
}
