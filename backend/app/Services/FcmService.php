<?php

namespace App\Services;

use App\Models\User;
use Firebase\JWT\JWT;
use GuzzleHttp\Client;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private ?Client $connection = null;
    private ?string $accessToken = null;
    private int $accessTokenExpiresAt = 0;

    /**
     * Send a push notification to a single user.
     */
    public function sendToUser(User $user, string $title, string $body, array $data = []): bool
    {
        if (! $user->fcm_token) {
            return false;
        }

        return $this->send($user->fcm_token, $title, $body, $data);
    }

    /**
     * Send a push notification to multiple users.
     */
    public function sendToUsers(iterable $users, string $title, string $body, array $data = []): int
    {
        $sent = 0;
        foreach ($users as $user) {
            if ($this->sendToUser($user, $title, $body, $data)) {
                $sent++;
            }
        }

        return $sent;
    }

    /**
     * Send a push notification to a single FCM token using FCM v1 HTTP API.
     */
    public function send(string $token, string $title, string $body, array $data = []): bool
    {
        $credentials = $this->credentials();
        $projectId = $credentials['project_id'] ?? null;

        if (! $projectId) {
            Log::warning('FCM: project_id not found in service account credentials.');
            return false;
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        // All data values must be strings for FCM.
        $stringData = [];
        foreach ($data as $key => $value) {
            $stringData[$key] = is_string($value) ? $value : (string) json_encode($value);
        }

        $message = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $stringData,
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'wslni_notifications',
                        'sound' => 'default',
                    ],
                ],
            ],
        ];

        try {
            $response = $this->authenticatedClient()
                ->post($url, $message);

            if ($response->successful()) {
                Log::info('FCM send OK', [
                    'title' => $title,
                    'token_tail' => substr($token, -12),
                    'response' => $response->json(),
                ]);
                return true;
            }

            $error = $response->json();
            $errorCode = $error['error']['details'][0]['errorCode'] ?? ($error['error']['status'] ?? '');

            // If token is invalid/unregistered, clear it from the user.
            if (in_array($errorCode, ['UNREGISTERED', 'INVALID_ARGUMENT', 'NOT_FOUND'], true)) {
                User::query()->where('fcm_token', $token)->update(['fcm_token' => null]);
                Log::info("FCM: Cleared invalid token: {$errorCode}");
            } else {
                Log::warning("FCM send failed: {$response->status()}", ['error' => $error]);
            }

            return false;
        } catch (\Throwable $e) {
            Log::error('FCM send exception: '.$e->getMessage());
            return false;
        }
    }

    private function authenticatedClient(): PendingRequest
    {
        if ($this->accessToken !== null && $this->accessTokenExpiresAt > time()) {
            return $this->http()->withToken($this->accessToken);
        }

        $cached = Cache::get('firebase.fcm.access-token');
        if (is_array($cached) && isset($cached['token'], $cached['expires_at']) && $cached['expires_at'] > time()) {
            $this->accessToken = $cached['token'];
            $this->accessTokenExpiresAt = $cached['expires_at'];
            return $this->http()->withToken($this->accessToken);
        }

        $credentials = $this->credentials();
        $now = time();

        $assertion = JWT::encode([
            'iss' => $credentials['client_email'],
            'sub' => $credentials['client_email'],
            'aud' => $credentials['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        ], $credentials['private_key'], 'RS256');

        $tokenResponse = Http::asForm()->timeout(10)->post($credentials['token_uri'], [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $assertion,
        ])->throw()->json('access_token');

        if (! is_string($tokenResponse) || $tokenResponse === '') {
            throw new \RuntimeException('FCM access token could not be created.');
        }

        $this->accessToken = $tokenResponse;
        $this->accessTokenExpiresAt = $now + 3300;

        Cache::put('firebase.fcm.access-token', [
            'token' => $this->accessToken,
            'expires_at' => $this->accessTokenExpiresAt,
        ], now()->addSeconds(3300));

        return $this->http()->withToken($this->accessToken);
    }

    /** One Guzzle client per process, so a long-lived queue worker keeps its TLS connection to FCM open. */
    private function http(): PendingRequest
    {
        return Http::setClient($this->connection ??= new Client)->timeout(10);
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
