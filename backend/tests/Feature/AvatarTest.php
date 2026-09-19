<?php

namespace Tests\Feature;

use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use Tests\Unit\ImageMetadataStripperTest;

class AvatarTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_upload_stores_a_metadata_free_copy_and_returns_its_path(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        Sanctum::actingAs($user);

        $response = $this->post('api/me/avatar', ['avatar' => $this->png(['tEXt' => "Location\x00SECRET"])], ['Accept' => 'application/json']);

        $response->assertOk();
        $path = $response->json('avatar_path');
        $this->assertStringStartsWith("avatars/{$user->id}-", $path);
        $this->assertSame($path, $user->fresh()->avatar_path);
        Storage::disk('public')->assertExists($path);
        $this->assertStringNotContainsString('SECRET', Storage::disk('public')->get($path));
    }

    public function test_new_upload_replaces_and_deletes_the_old_file(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        Sanctum::actingAs($user);

        $first = $this->post('api/me/avatar', ['avatar' => $this->png()], ['Accept' => 'application/json'])->json('avatar_path');
        $second = $this->post('api/me/avatar', ['avatar' => $this->png()], ['Accept' => 'application/json'])->json('avatar_path');

        $this->assertNotSame($first, $second);
        Storage::disk('public')->assertMissing($first);
        Storage::disk('public')->assertExists($second);
    }

    public function test_delete_removes_the_photo(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        Sanctum::actingAs($user);
        $path = $this->post('api/me/avatar', ['avatar' => $this->png()], ['Accept' => 'application/json'])->json('avatar_path');

        $this->deleteJson('api/me/avatar')->assertOk()->assertJson(['avatar_path' => null]);

        $this->assertNull($user->fresh()->avatar_path);
        Storage::disk('public')->assertMissing($path);
    }

    public function test_non_images_and_tiny_images_are_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'customer']));

        $fake = UploadedFile::fake()->createWithContent('photo.jpg', '<?php echo "hi";');
        $this->post('api/me/avatar', ['avatar' => $fake], ['Accept' => 'application/json'])
            ->assertUnprocessable();

        $tiny = UploadedFile::fake()->createWithContent('tiny.png', ImageMetadataStripperTest::png([], 10, 10));
        $this->post('api/me/avatar', ['avatar' => $tiny], ['Accept' => 'application/json'])
            ->assertUnprocessable();
    }

    public function test_upload_requires_authentication(): void
    {
        $this->post('api/me/avatar', ['avatar' => $this->png()], ['Accept' => 'application/json'])
            ->assertUnauthorized();
    }

    public function test_drivers_see_the_customer_photo_on_open_requests(): void
    {
        $customer = User::factory()->create(['role' => 'customer', 'avatar_path' => 'avatars/1-abc.jpg']);
        $driver = User::factory()->create(['role' => 'driver']);
        RideRequest::create([
            'customer_id' => $customer->id,
            'status' => 'pending',
            'pickup_address' => 'A',
            'pickup_lat' => 0,
            'pickup_lng' => 0,
            'dropoff_address' => 'B',
            'dropoff_lat' => 0,
            'dropoff_lng' => 0,
            'requested_at' => now(),
        ]);
        Sanctum::actingAs($driver);

        $this->getJson('api/rides?status=open')
            ->assertOk()
            ->assertJsonPath('0.customer.avatar_path', 'avatars/1-abc.jpg');
    }

    /** @param array<string, string> $extra */
    private function png(array $extra = []): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('photo.png', ImageMetadataStripperTest::png($extra, 96, 96));
    }
}
