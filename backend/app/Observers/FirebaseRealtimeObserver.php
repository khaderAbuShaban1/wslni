<?php

namespace App\Observers;

use App\Jobs\SyncFirebaseProjection;
use Illuminate\Database\Eloquent\Model;

class FirebaseRealtimeObserver
{
    public function saved(Model $model): void
    {
        $modelClass = $model::class;
        $modelId = (int) $model->getKey();

        // Dispatch on the 'firebase' queue when a worker is running, otherwise
        // fall back to the sync driver. Either way the projection runs AFTER
        // the database transaction commits (afterCommit is set in the job
        // constructor), so Firebase never sees uncommitted state.
        SyncFirebaseProjection::dispatch($modelClass, $modelId);
    }
}
