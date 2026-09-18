<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerWithdrawal;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CustomerWithdrawalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'هذا الإجراء متاح للزبائن فقط.');

        return response()->json([
            'wallet_balance' => (float) $user->wallet_balance,
            'withdrawals' => CustomerWithdrawal::query()
                ->where('customer_id', $user->id)
                ->latest()
                ->limit(50)
                ->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'هذا الإجراء متاح للزبائن فقط.');

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'method' => ['required', Rule::in(['bank', 'mobile_wallet'])],
            'account_name' => ['required', 'string', 'max:255'],
            'account_number' => ['required', 'string', 'max:100'],
        ], [
            'amount.required' => 'المبلغ مطلوب.',
            'amount.numeric' => 'المبلغ يجب أن يكون رقمًا.',
            'amount.min' => 'أدخل مبلغًا أكبر من صفر.',
            'method.required' => 'اختر طريقة التحويل.',
            'account_name.required' => 'اسم صاحب الحساب مطلوب.',
            'account_number.required' => 'رقم الحساب أو الجوال مطلوب.',
        ]);

        $result = DB::transaction(function () use ($user, $data): array {
            // Lock the wallet so two requests cannot both pass the balance
            // check and overdraw it.
            $lockedCustomer = User::query()->lockForUpdate()->findOrFail($user->id);
            $amount = round((float) $data['amount'], 2);

            if ((float) $lockedCustomer->wallet_balance < $amount) {
                return ['error' => 'رصيد المحفظة غير كافٍ.'];
            }

            // Reserved now and returned by the admin on rejection, so the same
            // balance cannot be requested twice while a review is pending.
            $lockedCustomer->decrement('wallet_balance', $amount);

            $withdrawal = CustomerWithdrawal::create([
                'customer_id' => $lockedCustomer->id,
                'amount' => $amount,
                'method' => $data['method'],
                'account_name' => $data['account_name'],
                'account_number' => $data['account_number'],
                'status' => 'pending',
            ]);

            $balanceAfter = (float) $lockedCustomer->fresh()->wallet_balance;

            // The balance drops here, so the statement must say why; otherwise
            // the customer sees money gone with no entry explaining it.
            WalletTransaction::create([
                'user_id' => $lockedCustomer->id,
                'created_by' => $lockedCustomer->id,
                'type' => 'withdrawal_hold',
                'amount' => -$amount,
                'balance_after' => $balanceAfter,
                'description' => "طلب سحب #{$withdrawal->id}",
            ]);

            return [
                'withdrawal' => $withdrawal,
                'wallet_balance' => $balanceAfter,
            ];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], 422);
        }

        return response()->json($result + ['message' => 'تم إرسال طلب السحب للمراجعة.'], 201);
    }
}
