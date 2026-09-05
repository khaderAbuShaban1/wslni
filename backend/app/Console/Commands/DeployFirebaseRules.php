<?php

namespace App\Console\Commands;

use App\Services\FirebaseRealtimeService;
use Illuminate\Console\Command;

class DeployFirebaseRules extends Command
{
    protected $signature = 'firebase:deploy-rules';
    protected $description = 'Deploy the repository Realtime Database Rules to Firebase.';

    public function handle(FirebaseRealtimeService $firebase): int
    {
        $path = base_path('../firebase.database.rules.json');
        if (! is_file($path)) {
            $this->error('firebase.database.rules.json was not found.');
            return self::FAILURE;
        }

        $firebase->deployRules((string) file_get_contents($path));
        $this->info('Firebase Realtime Database Rules deployed.');
        return self::SUCCESS;
    }
}
