<?php

namespace App\Jobs;

use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Services\FirebaseRealtimeService;
use Illuminate\Foundation\Bus\Dispatchable;

class SyncFirebaseProjection
{
    use Dispatchable;

    public function __construct(
        public string $modelClass,
        public int $modelId,
    ) {}


    public function handle(FirebaseRealtimeService $firebase): void
    {
        $model = $this->modelClass::find($this->modelId);
        if ($model === null) {
            return;
        }

        if ($model instanceof RideOffer) {
            $ride = RideRequest::find($model->ride_request_id);
            if ($ride !== null) {
                $firebase->syncRide($ride);
            }

            return;
        }

        if ($model instanceof RideRequest) {
            $firebase->syncRide($model);

            return;
        }

        $firebase->syncEntity($model);
    }
}
