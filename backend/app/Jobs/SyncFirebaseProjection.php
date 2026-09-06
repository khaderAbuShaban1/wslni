<?php

namespace App\Jobs;

use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Services\FirebaseRealtimeService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SyncFirebaseProjection implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 30;
    public int $uniqueFor = 10;
    public function __construct(
        public string $modelClass,
        public int $modelId,
    ) {
        $this->afterCommit();
    }

    public function uniqueId(): string
    {
        if (is_a($this->modelClass, RideOffer::class, true)) {
            $offer = RideOffer::find($this->modelId);
            return 'ride:'.($offer?->ride_request_id ?? $this->modelId);
        }

        return is_a($this->modelClass, RideRequest::class, true)
            ? 'ride:'.$this->modelId
            : $this->modelClass.':'.$this->modelId;
    }

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
