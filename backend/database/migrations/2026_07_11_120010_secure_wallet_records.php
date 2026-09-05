<?php

use App\Models\WalletDeposit;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email_otp_code', 255)->nullable()->change();
        });

        Schema::table('wallet_deposits', function (Blueprint $table) {
            $table->string('receipt_sha256', 64)->nullable()->unique()->after('receipt_path');
        });

        if (Schema::hasTable('wallet_transactions')) {
            Schema::table('wallet_transactions', function (Blueprint $table) {
                $table->foreignId('wallet_deposit_id')->nullable()->unique()->constrained('wallet_deposits')->nullOnDelete()->after('user_id');
                $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete()->after('wallet_deposit_id');
            });
        }

        $this->moveReceipts('public', 'local');
    }

    public function down(): void
    {
        $this->moveReceipts('local', 'public');

        Schema::table('wallet_deposits', function (Blueprint $table) {
            $table->dropUnique(['receipt_sha256']);
            $table->dropColumn('receipt_sha256');
        });

        if (Schema::hasTable('wallet_transactions')) {
            Schema::table('wallet_transactions', function (Blueprint $table) {
                $table->dropConstrainedForeignId('created_by');
                $table->dropConstrainedForeignId('wallet_deposit_id');
            });
        }

        Schema::table('users', function (Blueprint $table) {
            $table->string('email_otp_code', 6)->nullable()->change();
        });
    }

    private function moveReceipts(string $from, string $to): void
    {
        if (! Schema::hasTable('wallet_deposits')) {
            return;
        }

        foreach (WalletDeposit::query()->whereNotNull('receipt_path')->cursor() as $deposit) {
            $path = $deposit->receipt_path;

            if (! Storage::disk($from)->exists($path) || Storage::disk($to)->exists($path)) {
                continue;
            }

            $stream = Storage::disk($from)->readStream($path);
            if ($stream === null) {
                continue;
            }

            try {
                if (Storage::disk($to)->writeStream($path, $stream)) {
                    Storage::disk($from)->delete($path);
                }
            } finally {
                if (is_resource($stream)) {
                    fclose($stream);
                }
            }
        }
    }
};
