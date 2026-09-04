<?php

namespace App\Services;

use App\Models\DriverWithdrawal;
use App\Models\RideRequest;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Http;

class FirebaseRealtimeService
{
    public function syncRide(RideRequest $ride): void
    {
        if (! $this->isEnabled()) return;

        $ride->loadMissing([
            'customer:id,name,phone',
            'driver:id,name,phone',
            'driver.driverProfile',
            'offers.driver:id,name,phone',
            'offers.driver.driverProfile',
        ]);

        $this->put("ride_requests/{$ride->id}", $this->ridePayload($ride));
    }

    /** @return array<string, mixed> */
    private function ridePayload(RideRequest $ride): array
    {
        $ride->loadMissing([
            'customer:id,name,phone',
            'driver:id,name,phone',
            'driver.driverProfile',
            'offers.driver:id,name,phone',
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
                'driver_phone' => $driver?->phone ?? '',
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
            'customer_name' => $ride->customer?->name ?? 'زبون',
            'customer_phone' => $ride->customer?->phone ?? '',
            'driver_id' => $ride->driver_id,
            'driver_name' => $driver?->name ?? '',
            'driver_phone' => $driver?->phone ?? '',
            'vehicle' => $profile?->vehicle_type ?? '',
            'vehicle_plate' => $profile?->vehicle_plate ?? '',
            'pickup_address' => $ride->pickup_address,
            'dropoff_address' => $ride->dropoff_address,
            'notes' => $ride->notes ?? '',
            'status' => $ride->status,
            'actual_fare' => $ride->actual_fare === null ? null : (string) $ride->actual_fare,
            'platform_fee' => $ride->platform_fee === null ? null : (string) $ride->platform_fee,
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
        if (! $this->isEnabled()) return;
        $this->put("driver_withdrawals/{$withdrawal->driver_id}/{$withdrawal->id}", [
            'id' => $withdrawal->id,
            'driver_id' => $withdrawal->driver_id,
            'amount' => (float) $withdrawal->amount,
            'method' => $withdrawal->method,
            'account_name' => $withdrawal->account_name,
            'account_number' => $withdrawal->account_number,
            'status' => $withdrawal->status,
            'wallet_balance' => (float) ($withdrawal->driver()->value('wallet_balance') ?? 0),
            'created_at' => optional($withdrawal->created_at)->getTimestampMs(),
            'reviewed_at' => optional($withdrawal->reviewed_at)->getTimestampMs(),
        ]);
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

    private function request(string $method, string $path, ?array $data = null): bool
    {
        $url = rtrim((string) config('services.firebase.database_url'), '/');
        try {
            $this->authenticatedClient()->{$method}("{$url}/{$path}.json", $data)->throw();
            return true;
        } catch (\Throwable $exception) {
            report($exception);
            return false;
        }
    }

    private function authenticatedClient(): \Illuminate\Http\Client\PendingRequest
    {
        $path = (string) config('services.firebase.service_account_path');
        if ($path === '' || ! is_file($path)) {
            throw new \RuntimeException('Firebase service-account file is not configured.');
        }

        $credentials = json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
        $now = time();
        $assertion = JWT::encode([
            'iss' => $credentials['client_email'],
            'sub' => $credentials['client_email'],
            'aud' => $credentials['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email',
        ], $credentials['private_key'], 'RS256');

        $token = Http::asForm()->timeout(10)->post($credentials['token_uri'], [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $assertion,
        ])->throw()->json('access_token');

        if (! is_string($token) || $token === '') {
            throw new \RuntimeException('Firebase access token could not be created.');
        }

        return Http::withToken($token)->timeout(10);
    }
}
