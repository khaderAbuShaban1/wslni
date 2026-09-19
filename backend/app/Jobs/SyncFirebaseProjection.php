<?php

namespace App\Jobs;

use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Services\FirebaseRealtimeService;
use DateTimeInterface;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use RuntimeException;

class SyncFirebaseProjection implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function __construct(
        public string $modelClass,
        public int $modelId,
    ) {
        $this->onQueue('realtime');
        $this->afterCommit();
    }

    /** Offers are published as part of their ride, so they sync the ride. */
    public static function forModel(Model $model): void
    {
        if ($model instanceof RideOffer) {
            static::dispatch(RideRequest::class, (int) $model->ride_request_id);

            return;
        }

        static::dispatch($model::class, (int) $model->getKey());
    }

    /**
     * Several workers run in parallel. Serialising per record stops an older
     * snapshot from landing in Firebase after a newer one.
     */
    public function middleware(): array
    {
        return [
            (new WithoutOverlapping(class_basename($this->modelClass).':'.$this->modelId))
                ->releaseAfter(1)
                ->expireAfter(30),
        ];
    }

    public function retryUntil(): DateTimeInterface
    {
        return now()->addMinutes(2);
    }

    /** @return list<int> */
    public function backoff(): array
    {
        return [1, 3, 5];
    }

    public function handle(FirebaseRealtimeService $firebase): void
    {
        // Read at run time, not dispatch time: the job publishes whatever the
        // record looks like now, so duplicate jobs are harmless.
        $model = $this->modelClass::find($this->modelId);
        if ($model === null) {
            return;
        }

        if ($model instanceof RideRequest) {
            if (! $firebase->syncRide($model) && config('services.firebase.realtime_enabled')) {
                throw new RuntimeException("Firebase rejected syncing ride {$model->id}.");
            }

            return;
        }

        $firebase->syncEntity($model);
    }
}
