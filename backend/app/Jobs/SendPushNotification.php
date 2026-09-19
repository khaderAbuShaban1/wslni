<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;

class SendPushNotification implements ShouldQueue
{
    use Dispatchable, Queueable;

    // A failed send is not retried: a retry after a timeout that actually
    // delivered would show the user the same notification twice.
    public int $tries = 1;

    public function __construct(
        public int $userId,
        public string $title,
        public string $body,
        public array $data = [],
    ) {
        $this->onQueue('notifications');
        $this->afterCommit();
    }

    public function handle(FcmService $fcm): void
    {
        $user = User::find($this->userId);
        if ($user?->fcm_token) {
            $fcm->sendToUser($user, $this->title, $this->body, $this->data);
        }
    }
}
