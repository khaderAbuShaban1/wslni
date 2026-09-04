<?php

namespace App\Console\Commands;

use App\Models\RideRequest;
use App\Services\FirebaseRealtimeService;
use Illuminate\Console\Command;

class SyncFirebaseRides extends Command
{
    protected $signature = 'firebase:sync-rides {--fresh : Replace the Firebase ride_requests branch before syncing}';

    protected $description = 'Synchronize the MySQL ride_requests data to Firebase Realtime Database.';

    public function handle(FirebaseRealtimeService $firebase): int
    {
        $rides = RideRequest::query()
            ->with([
                'customer:id,name,phone',
                'driver:id,name,phone',
                'driver.driverProfile',
                'offers.driver:id,name,phone',
                'offers.driver.driverProfile',
            ])
            ->orderBy('id')
            ->get();

        if ($this->option('fresh')) {
            if (! $firebase->replaceRides($rides)) {
                $this->error('Firebase rejected the sync. Configure backend Firebase credentials and rules first.');

                return self::FAILURE;
            }
        } else {
            foreach ($rides as $ride) $firebase->syncRide($ride);
        }

        $this->info("Synchronized {$rides->count()} MySQL rides to Firebase.");

        return self::SUCCESS;
    }
}
