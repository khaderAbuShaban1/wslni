<?php

namespace App\Services;

use App\Enums\RideStatus;
use App\Models\RideOffer;
use App\Models\RideRequest;
use Illuminate\Support\Facades\DB;

class RideExpiryService
{
    public const EXPIRABLE = [
        RideStatus::Pending->value,
        RideStatus::ReceivingOffers->value,
        RideStatus::DriverSelected->value,
        'requested', // legacy alias of pending, still treated as open by Firebase sync
    ];

    public function __construct(private NotificationDispatcher $notifications) {}

    public static function isDue(RideRequest $ride): bool
    {
        return in_array($ride->status, self::EXPIRABLE, true)
            && $ride->expires_at !== null
            && $ride->expires_at->lte(now());
    }

    /** Cancels the ride if its window has passed. Safe to call concurrently. */
    public function expireIfDue(int $rideId): bool
    {
        $expired = DB::transaction(function () use ($rideId): ?RideRequest {
            $ride = RideRequest::query()->lockForUpdate()->find($rideId);
            if (! $ride || ! self::isDue($ride)) {
                return null;
            }

            RideOffer::query()
                ->where('ride_request_id', $ride->id)
                ->whereIn('status', ['pending', 'selected', 'inactive'])
                ->update(['status' => 'cancelled']);

            // driver_id is kept so the selected driver's Firebase copy also
            // receives the cancellation and the driver can be notified.
            $ride->update([
                'status' => RideStatus::Cancelled->value,
                'actual_fare' => null,
                'platform_fee' => null,
            ]);

            return $ride;
        });

        if ($expired === null) {
            return false;
        }

        $this->notifications->rideExpired($expired);

        return true;
    }

    public function expireAllDue(): int
    {
        $ids = RideRequest::query()
            ->whereIn('status', self::EXPIRABLE)
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now())
            ->pluck('id');

        return $ids->filter(fn (int $id) => $this->expireIfDue($id))->count();
    }
}
