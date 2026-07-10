<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WalletDeposit;
use App\Models\WalletPaymentAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class CustomerWalletController extends Controller
{
    public function show(User $customer): JsonResponse
    {
        abort_unless($customer->role === 'customer', 404);

        $paymentAccounts = WalletPaymentAccount::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get()
            ->map(fn (WalletPaymentAccount $account) => $this->paymentAccountPayload($account));

        $deposits = WalletDeposit::query()
            ->where('user_id', $customer->id)
            ->with('paymentAccount')
            ->latest()
            ->limit(10)
            ->get()
            ->map(fn (WalletDeposit $deposit) => $this->depositPayload($deposit));

        return response()->json([
            'wallet_balance' => (float) $customer->wallet_balance,
            'payment_accounts' => $paymentAccounts,
            'deposits' => $deposits,
        ]);
    }

    public function storeDeposit(Request $request, User $customer): JsonResponse
    {
        abort_unless($customer->role === 'customer', 404);

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:1'],
            'wallet_payment_account_id' => [
                'required',
                Rule::exists('wallet_payment_accounts', 'id')->where('is_active', true),
            ],
            'reference_number' => ['nullable', 'string', 'max:255', 'unique:wallet_deposits,reference_number'],
            'receipt_image' => ['required', 'image', 'max:5120'],
            'note' => ['nullable', 'string', 'max:5000'],
        ]);

        $paymentAccount = WalletPaymentAccount::query()->findOrFail($data['wallet_payment_account_id']);
        $path = $request->file('receipt_image')->store('wallet-deposits', 'public');

        $deposit = WalletDeposit::create([
            'user_id' => $customer->id,
            'wallet_payment_account_id' => $paymentAccount->id,
            'amount' => $data['amount'],
            'bank_name' => $paymentAccount->name,
            'reference_number' => $data['reference_number'] ?? null,
            'receipt_path' => $path,
            'status' => 'pending',
            'note' => $data['note'] ?? null,
        ])->load('paymentAccount');

        return response()->json([
            'message' => 'تم إرسال إشعار الدفع بنجاح، وسيتم مراجعة الطلب من الإدارة.',
            'deposit' => $this->depositPayload($deposit),
        ], 201);
    }

    private function paymentAccountPayload(WalletPaymentAccount $account): array
    {
        return [
            'id' => $account->id,
            'type' => $account->type,
            'invoice_number' => $account->invoiceNumber(),
            'name' => $account->name,
            'account_holder_name' => $account->account_holder_name,
            'account_number' => $account->account_number,
            'phone_number' => $account->phone_number,
            'instructions' => $account->instructions,
        ];
    }

    private function depositPayload(WalletDeposit $deposit): array
    {
        return [
            'id' => $deposit->id,
            'amount' => (float) $deposit->amount,
            'payment_account_name' => $deposit->paymentAccount?->name ?? $deposit->bank_name,
            'reference_number' => $deposit->reference_number,
            'receipt_url' => $deposit->receipt_path ? Storage::disk('public')->url($deposit->receipt_path) : null,
            'status' => $deposit->status,
            'note' => $deposit->note,
            'created_at' => $deposit->created_at,
        ];
    }
}
