<?php

namespace App\Observers;

use App\Jobs\SyncFirebaseProjection;
use App\Services\NotificationDispatcher;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class FirebaseRealtimeObserver
{
    public function __construct(
        private readonly NotificationDispatcher $notificationDispatcher,
    ) {}

    public function saved(Model $model): void
    {
        $modelClass = $model::class;
        $modelId = (int) $model->getKey();

        // Dispatch on the 'firebase' queue when a worker is running, otherwise
        // fall back to the sync driver. Either way the projection runs AFTER
        // the database transaction commits (afterCommit is set in the job
        // constructor), so Firebase never sees uncommitted state.
        SyncFirebaseProjection::dispatch($modelClass, $modelId);

        // FCM delivery is a network call. Running it inline would hold the
        // lockForUpdate() row locks open for the duration of the request to
        // Google, and a later rollback would leave a notification already sent
        // for a change that never landed. Deferring past the commit avoids
        // both. Outside a transaction this runs immediately.
        $dispatcher = $this->notificationDispatcher;
        DB::afterCommit(static fn () => $dispatcher->dispatch($model));
    }
}
