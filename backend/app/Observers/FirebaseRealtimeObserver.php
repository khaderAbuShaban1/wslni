<?php

namespace App\Observers;

use App\Jobs\SyncFirebaseProjection;
use App\Models\RideOffer;
use App\Models\RideRequest;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class FirebaseRealtimeObserver
{
    public function saved(Model $model): void
    {
        DB::afterCommit(function () use ($model): void {
            // Firebase is a projection, never part of the request critical
            // path. The database worker is reliable on the local Windows
            // development server and keeps remote calls off the mobile request.
            SyncFirebaseProjection::dispatch($model::class, (int) $model->getKey())
                ->onConnection('database')
                ->onQueue('firebase');
        });
    }
}
