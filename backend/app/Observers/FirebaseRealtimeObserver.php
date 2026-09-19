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
        // Queued and released only after the transaction commits, so the
        // request never waits on Firebase and Firebase never sees a rollback.
        SyncFirebaseProjection::forModel($model);

        // Deciding which notification to send needs the model's change state,
        // so it runs here; the actual FCM send is queued inside the dispatcher.
        $dispatcher = $this->notificationDispatcher;
        DB::afterCommit(static fn () => $dispatcher->dispatch($model));
    }
}
