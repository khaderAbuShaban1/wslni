<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverWithdrawal;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DriverWithdrawalController extends Controller
{
    public function index(User $driver): JsonResponse
    {
        abort_unless($driver->role === 'driver', 404);
        return response()->json([
            'wallet_balance' => (float) $driver->wallet_balance,
            'withdrawals' => DriverWithdrawal::query()->where('driver_id', $driver->id)->latest()->get(),
        ]);
    }

    public function store(Request $request, User $driver): JsonResponse
    {
        abort_unless($driver->role === 'driver', 404);
        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:10'],
            'method' => ['required', Rule::in(['bank', 'mobile_wallet'])],
            'account_name' => ['required', 'string', 'max:255'],
            'account_number' => ['required', 'string', 'max:100'],
        ]);

        $result = DB::transaction(function () use ($driver, $data): array {
            $lockedDriver = User::query()->lockForUpdate()->findOrFail($driver->id);
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
            return ['withdrawal' => $withdrawal, 'wallet_balance' => (float) $lockedDriver->fresh()->wallet_balance];
        });

        if (isset($result['error'])) return response()->json(['message' => $result['error']], 422);
        return response()->json($result + ['message' => 'تم إرسال طلب السحب للمراجعة.'], 201);
    }
}
