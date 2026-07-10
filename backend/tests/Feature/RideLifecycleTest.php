<?php

namespace Tests\Feature;

use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RideLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_accepting_an_offer_locks_the_driver_and_rejects_their_other_offers(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide();
        $otherRide = $this->createRide();
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 35,
            'status' => 'pending',
        ]);
        $otherOffer = RideOffer::create([
            'ride_request_id' => $otherRide->id,
            'driver_id' => $driver->id,
            'price' => 40,
            'status' => 'pending',
        ]);

        $this->patchJson("api/rides/{$ride->id}/offers/{$offer->id}/accept")
            ->assertOk()
            ->assertJsonPath('ride.status', 'accepted')
            ->assertJsonPath('ride.driver_id', $driver->id)
            ->assertJsonPath('ride.customer.phone', $ride->customer->phone);

        $this->assertDatabaseHas('ride_offers', [
            'id' => $otherOffer->id,
            'status' => 'rejected',
        ]);

        $this->getJson("api/rides?driver_id={$driver->id}&status=active")
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.id', $ride->id);
    }

    public function test_driver_with_an_active_ride_cannot_submit_or_receive_another_offer(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $activeRide = $this->createRide([
            'driver_id' => $driver->id,
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);
        $requestedRide = $this->createRide();

        $this->postJson("api/rides/{$requestedRide->id}/offers", [
            'driver_id' => $driver->id,
            'price' => 30,
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'لديك رحلة نشطة. أنهِها أو ألغها قبل تقديم عرض جديد.');

        $oldOffer = RideOffer::create([
            'ride_request_id' => $requestedRide->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        $this->patchJson("api/rides/{$requestedRide->id}/offers/{$oldOffer->id}/accept")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'هذا السائق مرتبط برحلة أخرى حاليًا. اختر سائقًا آخر.');

        $this->assertDatabaseHas('ride_requests', [
            'id' => $activeRide->id,
            'status' => 'accepted',
        ]);
        $this->assertDatabaseHas('ride_requests', [
            'id' => $requestedRide->id,
            'status' => 'requested',
            'driver_id' => null,
        ]);
    }

    public function test_driver_can_progress_and_complete_the_active_ride_in_order(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'driver_id' => $driver->id,
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);

        foreach (['arrived', 'in_progress', 'completed'] as $status) {
            $this->patchJson("api/rides/{$ride->id}", [
                'driver_id' => $driver->id,
                'status' => $status,
            ])->assertOk()->assertJsonPath('ride.status', $status);
        }

        $this->assertDatabaseHas('ride_requests', [
            'id' => $ride->id,
            'status' => 'completed',
        ]);
        $this->assertNotNull($ride->fresh()->completed_at);

        $this->getJson("api/rides?driver_id={$driver->id}&status=active")
            ->assertOk()
            ->assertJsonCount(0);
    }

    public function test_driver_cannot_skip_a_ride_status(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'driver_id' => $driver->id,
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);

        $this->patchJson("api/rides/{$ride->id}", [
            'driver_id' => $driver->id,
            'status' => 'completed',
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'لا يمكن نقل الرحلة إلى هذه الحالة الآن.');
    }

    private function createRide(array $attributes = []): RideRequest
    {
        return RideRequest::create(array_merge([
            'customer_id' => User::factory()->create(['role' => 'customer'])->id,
            'status' => 'requested',
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
