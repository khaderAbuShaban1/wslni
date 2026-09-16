<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FcmService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendFcmNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 15;

    public function __construct(
        public int $userId,
        public string $title,
        public string $body,
        public array $data = [],
    ) {
        $this->afterCommit();
        $this->onQueue('firebase');
    }

    public function handle(FcmService $fcm): void
    {
        $user = User::find($this->userId);
        if (! $user || ! $user->fcm_token) {
            return;
        }

        $fcm->sendToUser($user, $this->title, $this->body, $this->data);
    }
}
