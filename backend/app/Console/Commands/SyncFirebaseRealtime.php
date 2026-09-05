<?php

namespace App\Console\Commands;

use App\Models\{Complaint, DriverProfile, DriverWithdrawal, Promotion, RideRequest, User, WalletDeposit};
use App\Services\FirebaseRealtimeService;
use Illuminate\Console\Command;

class SyncFirebaseRealtime extends Command
{
    protected $signature = 'firebase:sync-realtime {--purge-legacy : Remove old Firebase branches that held sensitive data}';
    protected $description = 'Publish safe MySQL projections to Firebase Realtime Database.';

    public function handle(FirebaseRealtimeService $firebase): int
    {
        // Rebuild the scoped driver queue so closed rides cannot remain visible.
        $firebase->clearOpenRides();
        foreach (RideRequest::query()->cursor() as $ride) $firebase->syncRide($ride);
        foreach ([User::class, DriverProfile::class, WalletDeposit::class, DriverWithdrawal::class, Complaint::class, Promotion::class] as $model) {
            foreach ($model::query()->cursor() as $entity) $firebase->syncEntity($entity);
        }

        if ($this->option('purge-legacy')) $firebase->clearLegacySensitiveBranches();
        $this->info('Safe Firebase realtime projections synchronized from MySQL.');
        return self::SUCCESS;
    }
}
