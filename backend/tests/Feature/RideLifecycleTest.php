<?php

namespace Tests\Feature;

use App\Models\AppSetting;
use App\Models\DriverProfile;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RideLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_selecting_an_offer_waits_for_driver_confirmation_and_inactivates_other_ride_offers(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['customer_id' => $customer->id]);
        $otherDriver = User::factory()->create(['role' => 'driver']);
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 35,
            'status' => 'pending',
        ]);
        $otherOffer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $otherDriver->id,
            'price' => 40,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->patchJson("api/rides/{$ride->id}/offers/{$offer->id}/accept")
            ->assertOk()
            ->assertJsonPath('ride.status', 'driver_selected')
            ->assertJsonPath('ride.driver_id', $driver->id)
            ->assertJsonPath('ride.customer.phone', $ride->customer->phone);

        $this->assertDatabaseHas('ride_offers', [
            'id' => $otherOffer->id,
            'status' => 'inactive',
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson("api/rides/{$ride->id}/driver-confirmation", [
            'accepted' => true,
        ])->assertOk()->assertJsonPath('ride.status', 'driver_confirmed');

        $this->getJson('api/rides?status=active')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $ride->id);
    }

    public function test_driver_with_an_active_ride_cannot_submit_or_receive_another_offer(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::create([
            'user_id' => $driver->id,
            'license_number' => 'L999',
            'vehicle_type' => 'sedan',
            'vehicle_plate' => 'P999',
            'approval_status' => 'approved',
            'is_online' => true,
        ]);
        $this->createRide([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
            'accepted_at' => now(),
        ]);
        $requestedRide = $this->createRide(['customer_id' => $customer->id]);

        Sanctum::actingAs($driver, ['driver']);

        $this->postJson("api/rides/{$requestedRide->id}/offers", [
            'price' => 30,
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'لديك رحلة نشطة. أنهِها أو ألغها قبل تقديم عرض جديد.');

        $oldOffer = RideOffer::create([
            'ride_request_id' => $requestedRide->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->patchJson("api/rides/{$requestedRide->id}/offers/{$oldOffer->id}/accept")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'هذا السائق مرتبط برحلة أخرى حاليًا. اختر سائقًا آخر.');
    }

    public function test_driver_can_progress_and_complete_the_active_ride_in_order(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
            'accepted_at' => now(),
            'actual_fare' => 40,
        ]);
        AppSetting::query()->updateOrCreate(['key' => 'commission_percent'], ['value' => 15]);

        Sanctum::actingAs($driver, ['driver']);

        foreach (['driver_on_the_way', 'driver_arrived', 'trip_started', 'trip_completed'] as $status) {
            $this->patchJson("api/rides/{$ride->id}", [
                'status' => $status,
            ])->assertOk()->assertJsonPath('ride.status', $status);
        }

        $this->assertDatabaseHas('ride_requests', [
            'id' => $ride->id,
            'status' => 'trip_completed',
        ]);
        $this->assertNotNull($ride->fresh()->completed_at);
        $this->assertSame('60.00', $ride->customer->fresh()->wallet_balance);
        $this->assertSame('34.00', $driver->fresh()->wallet_balance);
        $this->assertDatabaseHas('ride_requests', ['id' => $ride->id, 'platform_fee' => 6]);
        $this->assertDatabaseCount('wallet_transactions', 3);

        $this->getJson('api/rides?status=active')
            ->assertOk()
            ->assertJsonCount(0);
    }

    public function test_driver_cannot_skip_a_ride_status(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
            'accepted_at' => now(),
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson("api/rides/{$ride->id}", [
            'status' => 'trip_completed',
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'لا يمكن نقل الرحلة إلى هذه الحالة الآن.');
    }

    public function test_trip_cannot_complete_when_customer_wallet_is_insufficient(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'driver_id' => $driver->id,
            'status' => 'trip_started',
            'actual_fare' => 150,
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson("api/rides/{$ride->id}", [
            'status' => 'trip_completed',
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'رصيد محفظة الزبون غير كافٍ لإكمال الرحلة.');

        $this->assertSame('100.00', $ride->customer->fresh()->wallet_balance);
        $this->assertSame('0.00', $driver->fresh()->wallet_balance);
        $this->assertDatabaseCount('wallet_transactions', 0);
    }

    public function test_driver_rejection_returns_ride_to_receiving_offers(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $otherDriver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['customer_id' => $customer->id, 'status' => 'receiving_offers']);
        $selected = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 35,
            'status' => 'pending',
        ]);
        RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $otherDriver->id,
            'price' => 40,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);
        $this->patchJson("api/rides/{$ride->id}/offers/{$selected->id}/accept")->assertOk();

        Sanctum::actingAs($driver, ['driver']);
        $this->patchJson("api/rides/{$ride->id}/driver-confirmation", [
            'accepted' => false,
        ])->assertOk()->assertJsonPath('ride.status', 'receiving_offers');

        $this->assertDatabaseHas('ride_requests', ['id' => $ride->id, 'driver_id' => null]);
        $this->assertDatabaseHas('ride_offers', ['id' => $selected->id, 'status' => 'rejected']);
    }

    public function test_receiving_offers_rides_remain_visible_in_open_requests(): void
    {
        $ride = $this->createRide(['status' => 'receiving_offers']);
        $driver = User::factory()->create(['role' => 'driver']);

        Sanctum::actingAs($driver, ['driver']);

        $this->getJson('api/rides?status=open')
            ->assertOk()
            ->assertJsonFragment(['id' => $ride->id, 'status' => 'receiving_offers']);
    }

    public function test_customer_can_rate_only_a_completed_trip(): void
    {
        $customer = $this->customer();
        $ride = $this->createRide(['customer_id' => $customer->id, 'status' => 'trip_completed']);

        Sanctum::actingAs($customer, ['customer']);

        $this->postJson("api/rides/{$ride->id}/rating", [
            'rating' => 5,
            'comment' => 'Great ride',
        ])->assertOk()->assertJsonPath('ride.status', 'rated');

        $this->assertDatabaseHas('ride_requests', [
            'id' => $ride->id,
            'rating' => 5,
            'rating_comment' => 'Great ride',
        ]);
    }

    private function customer(array $attributes = []): User
    {
        return User::factory()->create(array_merge([
            'role' => 'customer',
            'wallet_balance' => 100,
            'account_status' => 'active',
            'email_verified_at' => now(),
        ], $attributes));
    }

    private function createRide(array $attributes = []): RideRequest
    {
        return RideRequest::create(array_merge([
            'customer_id' => $attributes['customer_id'] ?? $this->customer()->id,
            'status' => 'pending',
            'pickup_address' => 'نقطة الانطلاق',
            'pickup_lat' => 0,
            'pickup_lng' => 0,
            'dropoff_address' => 'الوجهة',
            'dropoff_lat' => 0,
            'dropoff_lng' => 0,
            'requested_at' => now(),
        ], $attributes));
    }
}
