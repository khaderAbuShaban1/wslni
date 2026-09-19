<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('google_id')->nullable()->unique()->after('email');
            // Google accounts arrive without a phone number; the customer adds it later.
            $table->string('phone')->nullable()->change();
        });

        Schema::create('password_reset_codes', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('code_hash')->nullable();
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('code_expires_at')->nullable();
            $table->string('reset_token_hash', 64)->nullable();
            $table->timestamp('reset_token_expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_codes');

        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['google_id']);
            $table->dropColumn('google_id');
            $table->string('phone')->nullable(false)->change();
        });
    }
};
