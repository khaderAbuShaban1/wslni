<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // Covers the queries that run on every offer, accept and request, plus the
    // expiry sweep that runs every five seconds.
    public function up(): void
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            $table->index(['status', 'expires_at']);
            $table->index(['driver_id', 'status']);
            $table->index(['customer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            $table->dropIndex(['status', 'expires_at']);
            $table->dropIndex(['driver_id', 'status']);
            $table->dropIndex(['customer_id', 'status']);
        });
    }
};
