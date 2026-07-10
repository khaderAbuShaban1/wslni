<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wallet_payment_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('type')->default('bank');
            $table->string('name');
            $table->string('account_holder_name');
            $table->string('account_number')->nullable();
            $table->string('phone_number')->nullable();
            $table->text('instructions')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::table('wallet_deposits', function (Blueprint $table) {
            $table->foreignId('wallet_payment_account_id')
                ->nullable()
                ->after('user_id')
                ->constrained('wallet_payment_accounts')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('wallet_deposits', function (Blueprint $table) {
            $table->dropConstrainedForeignId('wallet_payment_account_id');
        });

        Schema::dropIfExists('wallet_payment_accounts');
    }
};
