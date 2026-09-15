<?php

namespace App\Observers;

use App\Jobs\SyncFirebaseProjection;
use App\Services\FirebaseRealtimeService;
use Illuminate\Database\Eloquent\Model;

class FirebaseRealtimeObserver
{
    public function saved(Model $model): void
    {
        $modelClass = $model::class;
        $modelId = (int) $model->getKey();

        // Do not dispatch a queued job here. The PHP development server does
        // not run a worker, so queued projections remain stale until manually
        // refreshed. Laravel invokes terminating callbacks after it has sent
        // the API response, keeping the UI quick while publishing realtime.
        app()->terminating(static function () use ($modelClass, $modelId): void {
            (new SyncFirebaseProjection($modelClass, $modelId))
                ->handle(app(FirebaseRealtimeService::class));
        });
    }
}
