<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            $table->unsignedTinyInteger('rating')->nullable()->after('completed_at');
            $table->text('rating_comment')->nullable()->after('rating');
        });

        DB::table('ride_requests')->where('status', 'requested')->update(['status' => 'pending']);
        DB::table('ride_requests')->where('status', 'accepted')->update(['status' => 'driver_confirmed']);
        DB::table('ride_requests')->where('status', 'arrived')->update(['status' => 'driver_arrived']);
        DB::table('ride_requests')->where('status', 'in_progress')->update(['status' => 'trip_started']);
        DB::table('ride_requests')->where('status', 'completed')->update(['status' => 'trip_completed']);
    }

    public function down(): void
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            $table->dropColumn(['rating', 'rating_comment']);
        });
    }
};
