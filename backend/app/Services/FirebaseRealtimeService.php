<?php

namespace App\Services;

use App\Models\DriverWithdrawal;
use Illuminate\Support\Facades\Http;

class FirebaseRealtimeService
{
    public function syncWithdrawal(DriverWithdrawal $withdrawal): void
    {
        $url = rtrim((string) config('services.firebase.database_url'), '/');
        if ($url === '') return;
        try {
            Http::timeout(5)->put("{$url}/driver_withdrawals/{$withdrawal->driver_id}/{$withdrawal->id}.json", [
            'id' => $withdrawal->id,
            'driver_id' => $withdrawal->driver_id,
            'amount' => (float) $withdrawal->amount,
            'method' => $withdrawal->method,
            'account_name' => $withdrawal->account_name,
            'account_number' => $withdrawal->account_number,
            'status' => $withdrawal->status,
            'wallet_balance' => (float) ($withdrawal->driver()->value('wallet_balance') ?? 0),
            'created_at' => optional($withdrawal->created_at)->getTimestampMs(),
            'reviewed_at' => optional($withdrawal->reviewed_at)->getTimestampMs(),
            ])->throw();
        } catch (\Throwable $exception) {
            report($exception);
        }
    }
}
