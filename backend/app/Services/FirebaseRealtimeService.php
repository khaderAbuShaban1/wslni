<?php

namespace App\Services;

use App\Models\DriverWithdrawal;
use App\Models\RideRequest;
use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class FirebaseRealtimeService
{
    private ?string $accessToken = null;
    private int $accessTokenExpiresAt = 0;
    /** Laravel authenticates users; this only grants Firebase read access. */
    public function customToken(User $user): ?string
    {
        if (! $this->isEnabled()) return null;

        try {
            $credentials = $this->credentials();
            $now = time();

            return JWT::encode([
                'iss' => $credentials['client_email'],
                'sub' => $credentials['client_email'],
                'aud' => 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
                'iat' => $now,
                'exp' => $now + 3600,
                'uid' => (string) $user->id,
                // Firebase transfers fields in `claims` to the resulting ID
                // token, where Realtime Database exposes them as auth.token.*.
                'claims' => [
                    'role' => $user->role,
                    'admin' => $user->isAdmin(),
                ],
            ], $credentials['private_key'], 'RS256');
        } catch (\Throwable $exception) {
            report($exception);
            return null;
        }
    }

    /** Publish only UI state: no phone numbers, account numbers, or balances. */
    public function syncEntity(object $entity): void
    {
        if (! $this->isEnabled()) return;

        $updatedAt = now()->getTimestampMs();
        if ($entity instanceof User) {
            $path = "users/{$entity->id}/state";
            $payload = ['id' => $entity->id, 'role' => $entity->role, 'account_status' => $entity->account_status, 'updated_at' => $updatedAt];
        } elseif ($entity instanceof \App\Models\DriverProfile) {
            $path = "drivers/{$entity->user_id}/state";
            $payload = ['driver_id' => $entity->user_id, 'approval_status' => $entity->approval_status, 'is_online' => (bool) $entity->is_online, 'rating' => (float) $entity->rating, 'updated_at' => $updatedAt];
        } elseif ($entity instanceof \App\Models\WalletDeposit) {
            $path = "users/{$entity->user_id}/deposits/{$entity->id}";
            $payload = ['id' => $entity->id, 'status' => $entity->status, 'amount' => (float) $entity->amount, 'updated_at' => $updatedAt];
        } elseif ($entity instanceof DriverWithdrawal) {
            $path = "users/{$entity->driver_id}/withdrawals/{$entity->id}";
            $payload = ['id' => $entity->id, 'status' => $entity->status, 'amount' => (float) $entity->amount, 'updated_at' => $updatedAt];
        } elseif ($entity instanceof \App\Models\Complaint) {
            $path = "users/{$entity->user_id}/complaints/{$entity->id}";
            $payload = ['id' => $entity->id, 'status' => $entity->status, 'category' => $entity->category, 'updated_at' => $updatedAt];
        } elseif ($entity instanceof \App\Models\Promotion) {
            $path = "public/promotions/{$entity->id}";
            $payload = ['id' => $entity->id, 'title' => $entity->title, 'code' => $entity->code, 'type' => $entity->type, 'value' => (float) $entity->value, 'is_active' => (bool) $entity->is_active, 'updated_at' => $updatedAt];
        } else {
            return;
        }

        $this->patch([
            $path => $payload,
            'admin/events/'.class_basename($entity).'/'.$entity->getKey() => ['id' => $entity->getKey(), 'updated_at' => $updatedAt],
        ]);
    }

    public function syncRide(RideRequest $ride): void
    {
        if (! $this->isEnabled()) return;

        $ride->loadMissing([
            'customer:id,name',
            'driver:id,name',
            'driver.driverProfile',
            'offers.driver:id,name',
            'offers.driver.driverProfile',
        ]);

        $payload = $this->ridePayload($ride);
        // A multi-location update reaches all subscribers atomically in one
        // request. Sending these copies one by one delayed the API response.
        $updates = [
            "ride_requests/{$ride->id}" => $payload,
            "users/{$ride->customer_id}/rides/{$ride->id}" => $payload,
            "admin/events/RideRequest/{$ride->id}" => [
                'id' => $ride->id,
                'status' => $ride->status,
                'updated_at' => optional($ride->updated_at)->getTimestampMs(),
            ],
        ];
        if ($ride->driver_id !== null) {
            $updates["users/{$ride->driver_id}/rides/{$ride->id}"] = $payload;
        }
        if (in_array($ride->status, ['pending', 'requested', 'receiving_offers'], true)) {
            $updates["drivers/open_rides/{$ride->id}"] = $payload;
        } else {
            $updates["drivers/open_rides/{$ride->id}"] = null;
        }
        $this->patch($updates);
    }

    /** @return array<string, mixed> */
    private function ridePayload(RideRequest $ride): array
    {
        $ride->loadMissing([
            'customer:id,name',
            'driver:id,name',
            'driver.driverProfile',
            'offers.driver:id,name',
            'offers.driver.driverProfile',
        ]);

        $offers = [];
        foreach ($ride->offers as $offer) {
            $driver = $offer->driver;
            $profile = $driver?->driverProfile;
            $offers[(string) $offer->driver_id] = [
                'id' => $offer->id,
                'offer_id' => $offer->id,
                'driver_id' => $offer->driver_id,
                'driver_name' => $driver?->name ?? 'سائق',
                'vehicle' => $profile?->vehicle_type ?? 'سيارة',
                'vehicle_plate' => $profile?->vehicle_plate ?? '',
                'rating' => (string) ($profile?->rating ?? '5.0'),
                'price' => (string) $offer->price,
                'notes' => $offer->notes ?? '',
                'eta' => 'قريبًا',
                'status' => $offer->status,
                'created_at' => optional($offer->created_at)->getTimestampMs(),
            ];
        }

        $driver = $ride->driver;
        $profile = $driver?->driverProfile;
        return [
            'id' => $ride->id,
            'customer_id' => $ride->customer_id,
            'customer_uid' => (string) $ride->customer_id,
            'customer_name' => $ride->customer?->name ?? 'زبون',
            'driver_id' => $ride->driver_id,
            'driver_uid' => $ride->driver_id === null ? null : (string) $ride->driver_id,
            'driver_name' => $driver?->name ?? '',
            'vehicle' => $profile?->vehicle_type ?? '',
            'vehicle_plate' => $profile?->vehicle_plate ?? '',
            'pickup_address' => $ride->pickup_address,
            'dropoff_address' => $ride->dropoff_address,
            'notes' => $ride->notes ?? '',
            'status' => $ride->status,
            'actual_fare' => $ride->actual_fare === null ? null : (string) $ride->actual_fare,
            'rating' => $ride->rating,
            'rating_comment' => $ride->rating_comment,
            'requested_at' => optional($ride->requested_at)->getTimestampMs(),
            'accepted_at' => optional($ride->accepted_at)->getTimestampMs(),
            'completed_at' => optional($ride->completed_at)->getTimestampMs(),
            'updated_at' => optional($ride->updated_at)->getTimestampMs(),
            'offers' => $offers,
        ];
    }

    public function replaceRides(iterable $rides): bool
    {
        if (! $this->isEnabled()) return false;

        $payload = [];
        foreach ($rides as $ride) {
            $payload[(string) $ride->id] = $this->ridePayload($ride);
        }

        // A single PUT replaces the whole branch. This is important because
        // numeric Firebase keys are represented as sparse arrays; deleting
        // and then writing individual keys can leave stale array entries.
        return $this->put('ride_requests', $payload);
    }

    public function syncWithdrawal(DriverWithdrawal $withdrawal): void
    {
        $this->syncEntity($withdrawal);
    }

    /** Removes a legacy path that previously carried financial details. */
    public function clearLegacySensitiveBranches(): void
    {
        if ($this->isEnabled()) $this->request('delete', 'driver_withdrawals');
    }

    public function clearOpenRides(): void
    {
        if ($this->isEnabled()) $this->request('delete', 'drivers/open_rides');
    }

    /** Deploys the checked-in RTDB rules using the configured service account. */
    public function deployRules(string $rules): void
    {
        $payload = json_decode($rules, true, 512, JSON_THROW_ON_ERROR);
        $url = rtrim((string) config('services.firebase.database_url'), '/');
        $this->authenticatedClient()->put($url.'/.settings/rules.json', $payload)->throw();
    }

    private function isEnabled(): bool
    {
        return (bool) config('services.firebase.realtime_enabled')
            && rtrim((string) config('services.firebase.database_url'), '/') !== '';
    }

    private function put(string $path, array $data): bool
    {
        return $this->request('put', $path, $data);
    }

    /** @param array<string, mixed> $updates */
    private function patch(array $updates): bool
    {
        return $this->request('patch', '', $updates);
    }

    private function request(string $method, string $path, ?array $data = null): bool
    {
        $url = rtrim((string) config('services.firebase.database_url'), '/');
        try {
            $endpoint = $path === '' ? "{$url}/.json" : "{$url}/{$path}.json";
            $this->authenticatedClient()->{$method}($endpoint, $data)->throw();
            return true;
        } catch (\Throwable $exception) {
            report($exception);
            return false;
        }
    }

    private function authenticatedClient(): \Illuminate\Http\Client\PendingRequest
    {
        $credentials = $this->credentials();
        if ($this->accessToken !== null && $this->accessTokenExpiresAt > time()) {
            return Http::withToken($this->accessToken)->timeout(10);
        }

        $cached = Cache::get('firebase.realtime.access-token');
        if (is_array($cached) && isset($cached['token'], $cached['expires_at']) && $cached['expires_at'] > time()) {
            $this->accessToken = $cached['token'];
            $this->accessTokenExpiresAt = $cached['expires_at'];
            return Http::withToken($this->accessToken)->timeout(10);
        }

        $now = time();
        $assertion = JWT::encode([
            'iss' => $credentials['client_email'],
            'sub' => $credentials['client_email'],
            'aud' => $credentials['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email',
        ], $credentials['private_key'], 'RS256');

        $token = Http::asForm()->timeout(10)->post($credentials['token_uri'], [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $assertion,
        ])->throw()->json('access_token');

        if (! is_string($token) || $token === '') {
            throw new \RuntimeException('Firebase access token could not be created.');
        }

        $this->accessToken = $token;
        $this->accessTokenExpiresAt = $now + 3300;
        Cache::put('firebase.realtime.access-token', [
            'token' => $this->accessToken,
            'expires_at' => $this->accessTokenExpiresAt,
        ], now()->addSeconds(3300));

        return Http::withToken($this->accessToken)->timeout(10);
    }

    /** @return array<string, string> */
    private function credentials(): array
    {
        $path = (string) config('services.firebase.service_account_path');
        if ($path === '' || ! is_file($path)) {
            throw new \RuntimeException('Firebase service-account file is not configured.');
        }

        return json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
    }
}
