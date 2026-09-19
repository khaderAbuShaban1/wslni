<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    // Rides opened before expires_at existed would otherwise stay open forever.
    public function up(): void
    {
        DB::table('ride_requests')
            ->whereNull('expires_at')
            ->whereIn('status', ['requested', 'pending', 'receiving_offers', 'driver_selected'])
            ->update([
                'expires_at' => DB::raw('DATE_ADD(COALESCE(requested_at, created_at), INTERVAL 15 MINUTE)'),
            ]);
    }

    public function down(): void
    {
        //
    }
};
