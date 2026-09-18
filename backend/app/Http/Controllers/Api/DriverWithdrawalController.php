<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverWithdrawal;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DriverWithdrawalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        return response()->json([
            'wallet_balance' => (float) $user->wallet_balance,
            'withdrawals' => DriverWithdrawal::query()->where('driver_id', $user->id)->latest()->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:10'],
            'method' => ['required', Rule::in(['bank', 'mobile_wallet'])],
            'account_name' => ['required', 'string', 'max:255'],
            'account_number' => ['required', 'string', 'max:100'],
        ]);

        $result = DB::transaction(function () use ($user, $data): array {
            $lockedDriver = User::query()->lockForUpdate()->findOrFail($user->id);
            $amount = round((float) $data['amount'], 2);
            if ((float) $lockedDriver->wallet_balance < $amount) {
                return ['error' => 'رصيد الأرباح المتاح غير كافٍ.'];
            }
            $lockedDriver->decrement('wallet_balance', $amount);
            $withdrawal = DriverWithdrawal::create([
                'driver_id' => $lockedDriver->id,
                'amount' => $amount,
                'method' => $data['method'],
                'account_name' => $data['account_name'],
                'account_number' => $data['account_number'],
                'status' => 'pending',
            ]);

            $balanceAfter = (float) $lockedDriver->fresh()->wallet_balance;

            // The balance drops here, so the ledger must record why; otherwise
            // the driver's earnings shrink with no entry explaining it.
            WalletTransaction::create([
                'user_id' => $lockedDriver->id,
                'created_by' => $lockedDriver->id,
                'type' => 'withdrawal_hold',
                'amount' => -$amount,
                'balance_after' => $balanceAfter,
                'description' => "طلب سحب #{$withdrawal->id}",
            ]);

            return ['withdrawal' => $withdrawal, 'wallet_balance' => $balanceAfter];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], 422);
        }

        return response()->json($result + ['message' => 'تم إرسال طلب السحب للمراجعة.'], 201);
    }
}
