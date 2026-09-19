<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

/**
 * Verifies a Google Sign-In ID token locally against Google's published keys,
 * so a token minted for another app can never sign someone in here.
 */
class GoogleIdTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/oauth2/v3/certs';

    private const ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    /**
     * @return array{sub: string, email: string, name: ?string, picture: ?string}
     *
     * @throws RuntimeException when the token is not a valid Google token for this app
     */
    public function verify(string $idToken): array
    {
        $clientIds = (array) config('services.google.client_ids');
        if ($clientIds === []) {
            throw new RuntimeException('Google sign-in is not configured.');
        }

        try {
            JWT::$leeway = 60;
            $claims = (array) JWT::decode($idToken, JWK::parseKeySet($this->keys()));
        } catch (Throwable $exception) {
            throw new RuntimeException('Invalid Google token.', previous: $exception);
        }

        $audience = $claims['aud'] ?? null;
        if (! in_array($claims['iss'] ?? null, self::ISSUERS, true)
            || ! is_string($audience) || ! in_array($audience, $clientIds, true)
            || empty($claims['sub']) || empty($claims['email'])
            || ($claims['email_verified'] ?? false) !== true) {
            throw new RuntimeException('Google token rejected.');
        }

        return [
            'sub' => (string) $claims['sub'],
            'email' => strtolower((string) $claims['email']),
            'name' => isset($claims['name']) ? (string) $claims['name'] : null,
            'picture' => isset($claims['picture']) ? (string) $claims['picture'] : null,
        ];
    }

    /** @return array{keys: list<array<string, string>>} */
    private function keys(): array
    {
        return Cache::remember('google.oauth.certs', now()->addHours(6), function (): array {
            $keys = Http::timeout(10)->get(self::CERTS_URL)->throw()->json();
            if (! is_array($keys) || empty($keys['keys'])) {
                throw new RuntimeException('Google signing keys are unavailable.');
            }

            return $keys;
        });
    }
}
