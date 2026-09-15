<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    // ----------------------------------------------------------------
    // Unauthenticated requests must be rejected
    // ----------------------------------------------------------------

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $ride = $this->createRide();

        $this->getJson('api/rides')->assertUnauthorized();
        $this->postJson('api/rides', ['pickup_address' => 'A', 'dropoff_address' => 'B'])->assertUnauthorized();
        $this->getJson("api/rides/{$ride->id}")->assertUnauthorized();
        $this->patchJson("api/rides/{$ride->id}", ['status' => 'cancelled'])->assertUnauthorized();
        $this->postJson("api/rides/{$ride->id}/offers", ['price' => 30])->assertUnauthorized();
        $this->postJson("api/rides/{$ride->id}/rating", ['rating' => 5])->assertUnauthorized();
        $this->getJson('api/drivers/me/withdrawals')->assertUnauthorized();
        $this->postJson('api/drivers/me/withdrawals', ['amount' => 50, 'method' => 'bank', 'account_name' => 'X', 'account_number' => '1'])->assertUnauthorized();
        $this->patchJson('api/drivers/me/status', ['is_online' => false])->assertUnauthorized();
        $this->getJson('api/customers/me')->assertUnauthorized();
        $this->patchJson('api/customers/me', ['name' => 'X'])->assertUnauthorized();
        $this->postJson('api/auth/change-password', ['current_password' => 'x', 'password' => 'y', 'password_confirmation' => 'y'])->assertUnauthorized();
    }

    // ----------------------------------------------------------------
    // Role enforcement: a customer cannot act as a driver
    // ----------------------------------------------------------------

    public function test_customer_cannot_submit_a_driver_offer(): void
    {
        $customer = $this->customer();
        $ride = $this->createRide();
        Sanctum::actingAs($customer, ['customer']);

        $this->postJson("api/rides/{$ride->id}/offers", ['price' => 30])
            ->assertForbidden();
    }

    public function test_customer_cannot_update_ride_status(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
        ]);
        Sanctum::actingAs($customer, ['customer']);

        $this->patchJson("api/rides/{$ride->id}", ['status' => 'driver_on_the_way'])
            ->assertForbidden();
    }

    public function test_customer_cannot_access_driver_withdrawals(): void
    {
        $customer = $this->customer();
        Sanctum::actingAs($customer, ['customer']);

        $this->getJson('api/drivers/me/withdrawals')->assertForbidden();
        $this->postJson('api/drivers/me/withdrawals', [
            'amount' => 50,
            'method' => 'bank',
            'account_name' => 'X',
            'account_number' => '1',
        ])->assertForbidden();
    }

    // ----------------------------------------------------------------
    // Role enforcement: a driver cannot act as a customer
    // ----------------------------------------------------------------

    public function test_driver_cannot_create_a_ride(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        Sanctum::actingAs($driver, ['driver']);

        $this->postJson('api/rides', ['pickup_address' => 'A', 'dropoff_address' => 'B'])
            ->assertForbidden();
    }

    public function test_driver_cannot_accept_an_offer(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['customer_id' => $customer->id]);
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson("api/rides/{$ride->id}/offers/{$offer->id}/accept")
            ->assertForbidden();
    }

    public function test_driver_cannot_rate_a_ride(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['driver_id' => $driver->id, 'status' => 'trip_completed']);

        Sanctum::actingAs($driver, ['driver']);

        $this->postJson("api/rides/{$ride->id}/rating", ['rating' => 5])
            ->assertForbidden();
    }

    // ----------------------------------------------------------------
    // Cross-user: a driver cannot act on another driver's ride
    // ----------------------------------------------------------------

    public function test_driver_cannot_update_another_drivers_ride(): void
    {
        $driverA = User::factory()->create(['role' => 'driver']);
        $driverB = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'driver_id' => $driverA->id,
            'status' => 'driver_confirmed',
        ]);

        Sanctum::actingAs($driverB, ['driver']);

        $this->patchJson("api/rides/{$ride->id}", ['status' => 'driver_on_the_way'])
            ->assertForbidden();
    }

    // ----------------------------------------------------------------
    // Cross-user: a customer cannot accept offers on another customer's ride
    // ----------------------------------------------------------------

    public function test_customer_cannot_accept_offer_on_another_customers_ride(): void
    {
        $customerA = $this->customer();
        $customerB = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['customer_id' => $customerA->id]);
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customerB, ['customer']);

        $this->patchJson("api/rides/{$ride->id}/offers/{$offer->id}/accept")
            ->assertForbidden();
    }

    public function test_customer_cannot_rate_another_customers_ride(): void
    {
        $customerA = $this->customer();
        $customerB = $this->customer();
        $ride = $this->createRide(['customer_id' => $customerA->id, 'status' => 'trip_completed']);

        Sanctum::actingAs($customerB, ['customer']);

        $this->postJson("api/rides/{$ride->id}/rating", ['rating' => 5])
            ->assertUnprocessable();
    }

    // ----------------------------------------------------------------
    // Driver status toggle
    // ----------------------------------------------------------------

    public function test_driver_can_toggle_online_status(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::create([
            'user_id' => $driver->id,
            'license_number' => 'L123',
            'vehicle_type' => 'sedan',
            'vehicle_plate' => 'P123',
            'approval_status' => 'approved',
            'is_online' => true,
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson('api/drivers/me/status', ['is_online' => false])
            ->assertOk()
            ->assertJsonPath('driver.is_online', false);
    }

    // ----------------------------------------------------------------
    // Customer ride cancellation
    // ----------------------------------------------------------------

    public function test_customer_can_cancel_a_pending_ride(): void
    {
        $customer = $this->customer();
        $ride = $this->createRide(['customer_id' => $customer->id, 'status' => 'pending']);
        Sanctum::actingAs($customer, ['customer']);

        $this->deleteJson("api/rides/{$ride->id}")
            ->assertOk()
            ->assertJsonPath('message', 'تم إلغاء الرحلة بنجاح.');

        $this->assertDatabaseHas('ride_requests', ['id' => $ride->id, 'status' => 'cancelled']);
    }

    public function test_customer_can_cancel_a_ride_with_offers(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['customer_id' => $customer->id, 'status' => 'receiving_offers']);
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->deleteJson("api/rides/{$ride->id}")
            ->assertOk();

        $this->assertDatabaseHas('ride_requests', ['id' => $ride->id, 'status' => 'cancelled', 'driver_id' => null]);
        $this->assertDatabaseHas('ride_offers', ['id' => $offer->id, 'status' => 'cancelled']);
    }

    public function test_customer_cannot_cancel_ride_after_driver_confirmed(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide([
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
            'status' => 'driver_confirmed',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->deleteJson("api/rides/{$ride->id}")
            ->assertUnprocessable();

        $this->assertDatabaseHas('ride_requests', ['id' => $ride->id, 'status' => 'driver_confirmed']);
    }

    public function test_customer_cannot_cancel_another_customers_ride(): void
    {
        $customerA = $this->customer();
        $customerB = $this->customer();
        $ride = $this->createRide(['customer_id' => $customerA->id, 'status' => 'pending']);

        Sanctum::actingAs($customerB, ['customer']);

        $this->deleteJson("api/rides/{$ride->id}")
            ->assertForbidden();
    }

    public function test_driver_cannot_cancel_ride_via_delete(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $ride = $this->createRide(['status' => 'pending']);

        Sanctum::actingAs($driver, ['driver']);

        $this->deleteJson("api/rides/{$ride->id}")
            ->assertForbidden();
    }

    // ----------------------------------------------------------------
    // Driver approval_status enforcement
    // ----------------------------------------------------------------

    public function test_unapproved_driver_cannot_submit_offer(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::create([
            'user_id' => $driver->id,
            'license_number' => 'L123',
            'vehicle_type' => 'sedan',
            'vehicle_plate' => 'P123',
            'approval_status' => 'pending',
            'is_online' => false,
        ]);
        $ride = $this->createRide(['status' => 'receiving_offers']);

        Sanctum::actingAs($driver, ['driver']);

        $this->postJson("api/rides/{$ride->id}/offers", ['price' => 30])
            ->assertForbidden();
    }

    public function test_unapproved_driver_cannot_go_online(): void
    {
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::create([
            'user_id' => $driver->id,
            'license_number' => 'L456',
            'vehicle_type' => 'sedan',
            'vehicle_plate' => 'P456',
            'approval_status' => 'pending',
            'is_online' => false,
        ]);

        Sanctum::actingAs($driver, ['driver']);

        $this->patchJson('api/drivers/me/status', ['is_online' => true])
            ->assertForbidden();
    }

    // ----------------------------------------------------------------
    // Customer cannot create duplicate active rides
    // ----------------------------------------------------------------

    public function test_customer_cannot_create_ride_while_one_is_active(): void
    {
        $customer = $this->customer();
        $this->createRide(['customer_id' => $customer->id, 'status' => 'receiving_offers']);

        Sanctum::actingAs($customer, ['customer']);

        $this->postJson('api/rides', [
            'pickup_address' => 'مكان جديد',
            'dropoff_address' => 'وجهة جديدة',
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'لديك رحلة نشطة بالفعل. أكملها أو ألغها قبل طلب رحلة جديدة.');
    }

    public function test_customer_can_create_ride_after_previous_completed(): void
    {
        $customer = $this->customer();
        $this->createRide(['customer_id' => $customer->id, 'status' => 'trip_completed']);

        Sanctum::actingAs($customer, ['customer']);

        $this->postJson('api/rides', [
            'pickup_address' => 'مكان جديد',
            'dropoff_address' => 'وجهة جديدة',
        ])->assertCreated();
    }

    // ----------------------------------------------------------------
    // Accepting an offer re-checks driver approval
    // ----------------------------------------------------------------

    public function test_cannot_accept_offer_from_revoked_driver(): void
    {
        $customer = $this->customer();
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::create([
            'user_id' => $driver->id,
            'license_number' => 'L789',
            'vehicle_type' => 'sedan',
            'vehicle_plate' => 'P789',
            'approval_status' => 'rejected',
            'is_online' => false,
        ]);
        $ride = $this->createRide(['customer_id' => $customer->id, 'status' => 'receiving_offers']);
        $offer = RideOffer::create([
            'ride_request_id' => $ride->id,
            'driver_id' => $driver->id,
            'price' => 30,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($customer, ['customer']);

        $this->patchJson("api/rides/{$ride->id}/offers/{$offer->id}/accept")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'هذا السائق لم يعد معتمدًا. اختر سائقًا آخر.');
    }

    // ----------------------------------------------------------------
    // Auth routes remain public
    // ----------------------------------------------------------------

    public function test_login_does_not_require_a_token(): void
    {
        $this->postJson('api/auth/login', [
            'email' => 'no@example.com',
            'password' => 'wrong',
        ])->assertStatus(422);
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

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
