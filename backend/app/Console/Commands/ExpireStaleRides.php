<?php

namespace App\Console\Commands;

use App\Services\RideExpiryService;
use Illuminate\Console\Command;

class ExpireStaleRides extends Command
{
    protected $signature = 'rides:expire';
    protected $description = 'Cancel rides whose 15-minute window has elapsed';

    public function handle(RideExpiryService $expiry): int
    {
        $count = $expiry->expireAllDue();

        if ($count) {
            $this->info("Expired {$count} ride(s).");
        }

        return self::SUCCESS;
    }
}
