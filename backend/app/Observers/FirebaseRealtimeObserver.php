<?php

namespace App\Observers;

use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Services\FirebaseRealtimeService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class FirebaseRealtimeObserver
{
    public function saved(Model $model): void
    {
        DB::afterCommit(function () use ($model): void {
            $firebase = app(FirebaseRealtimeService::class);

            if ($model instanceof RideRequest) {
                $firebase->syncRide($model->fresh());
                return;
            }

            if ($model instanceof RideOffer) {
                if ($ride = RideRequest::find($model->ride_request_id)) $firebase->syncRide($ride);
                return;
            }

            $firebase->syncEntity($model->fresh());
        });
    }
}
