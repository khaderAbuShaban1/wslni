<?php

namespace Tests\Feature;

use App\Models\AppSetting;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminAnalyticsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_analytics_page_loads_on_mysql(): void
    {
        AppSetting::create([
            'key' => 'commission_percent',
            'value' => '15',
        ]);

        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'phone' => '0597111000',
            'password' => Hash::make('123123123'),
            'role' => 'admin',
            'account_status' => 'active',
            'email_verified_at' => now(),
        ]);

        RideRequest::create([
            'customer_id' => $admin->id,
            'status' => 'completed',
            'pickup_address' => 'موقع الانطلاق',
            'pickup_lat' => 31.95,
            'pickup_lng' => 35.93,
            'dropoff_address' => 'موقع الوصول',
            'dropoff_lat' => 31.96,
            'dropoff_lng' => 35.94,
            'fare_estimate' => 20,
            'actual_fare' => 22,
            'distance_km' => 5.5,
            'commission_percent' => 15,
            'platform_fee' => 3.3,
            'requested_at' => now()->subDay(),
            'accepted_at' => now()->subHours(20),
            'completed_at' => now()->subHours(19),
        ]);

        $this->actingAs($admin)
            ->get(route('admin.analytics.index'))
            ->assertOk()
            ->assertSee('الإحصائيات');
    }
}
