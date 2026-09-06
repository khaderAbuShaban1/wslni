<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Deposit and withdrawal transactions do not belong to a ride. Older
     * installations created this column as NOT NULL before the schema was
     * corrected in the original create-table migration.
     */
    public function up(): void
    {
        DB::statement('ALTER TABLE wallet_transactions MODIFY ride_request_id BIGINT UNSIGNED NULL');
    }

    public function down(): void
    {
        // Reverting would lose valid deposit/withdrawal transaction records.
    }
};
