<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\DriverWithdrawal;
use App\Models\WalletDeposit;
use App\Models\WalletPaymentAccount;
use App\Services\FirebaseRealtimeService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class WalletsController extends Controller
{
    public function paymentAccounts(): View
    {
        $paymentAccounts = WalletPaymentAccount::query()
            ->orderByDesc('is_active')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return view('admin.wallet-payment-accounts', [
            'paymentAccounts' => $paymentAccounts,
            'activeCount' => $paymentAccounts->where('is_active', true)->count(),
            'inactiveCount' => $paymentAccounts->where('is_active', false)->count(),
        ]);
    }

    public function paymentAccountInvoice(WalletPaymentAccount $walletPaymentAccount): View
    {
        $depositsQuery = WalletDeposit::query()
            ->where(function ($query) use ($walletPaymentAccount): void {
                $query->where('wallet_payment_account_id', $walletPaymentAccount->id)
                    ->orWhere(function ($legacyQuery) use ($walletPaymentAccount): void {
                        $legacyQuery->whereNull('wallet_payment_account_id')
                            ->where('bank_name', $walletPaymentAccount->name);
                    });
            });

        $deposits = (clone $depositsQuery)
            ->with('user:id,name,email,phone')
            ->latest()
            ->limit(20)
            ->get();

        return view('admin.wallet-payment-account-invoice', [
            'account' => $walletPaymentAccount,
            'deposits' => $deposits,
            'totalDeposits' => (clone $depositsQuery)->count(),
            'pendingDeposits' => (clone $depositsQuery)->where('status', 'pending')->count(),
            'approvedDeposits' => (clone $depositsQuery)->where('status', 'approved')->count(),
            'rejectedDeposits' => (clone $depositsQuery)->where('status', 'rejected')->count(),
            'approvedTotal' => (float) (clone $depositsQuery)->where('status', 'approved')->sum('amount'),
        ]);
    }

    public function index(Request $request): View
    {
        $status = $request->string('status')->toString();
        $search = trim($request->string('search')->toString());

        $deposits = WalletDeposit::query()
            ->with(['user:id,name,email,phone,wallet_balance', 'paymentAccount', 'reviewer:id,name'])
            ->when($status && $status !== 'all', fn ($query) => $query->where('status', $status))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($nested) use ($search) {
                    $nested->where('reference_number', 'like', "%{$search}%")
                        ->orWhere('bank_name', 'like', "%{$search}%")
                        ->orWhereHas('user', function ($userQuery) use ($search) {
                            $userQuery->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%")
                                ->orWhere('phone', 'like', "%{$search}%");
                        });

                    if (is_numeric($search)) {
                        $nested->orWhere('id', (int) $search);
                    }
                });
            })
            ->latest()
            ->get();

        $pendingDeposits = WalletDeposit::query()
            ->with(['user:id,name,email,phone,wallet_balance', 'paymentAccount'])
            ->where('status', 'pending')
            ->oldest()
            ->get();

        return view('admin.wallets', [
            'deposits' => $deposits,
            'pendingDeposits' => $pendingDeposits,
            'pendingCustomerCounts' => $pendingDeposits->groupBy('user_id')->map->count(),
            'status' => $status ?: 'all',
            'search' => $search,
            'users' => User::query()->where('role', 'customer')->orderBy('name')->get(['id', 'name', 'wallet_balance']),
            'paymentAccounts' => WalletPaymentAccount::query()
                ->orderByDesc('is_active')
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
            'pendingCount' => WalletDeposit::query()->where('status', 'pending')->count(),
            'approvedCount' => WalletDeposit::query()->where('status', 'approved')->count(),
            'rejectedCount' => WalletDeposit::query()->where('status', 'rejected')->count(),
            'totalCredited' => (float) WalletDeposit::query()->where('status', 'approved')->sum('amount'),
            'totalBalances' => (float) User::query()->sum('wallet_balance'),
            'driverWithdrawals' => DriverWithdrawal::query()->with('driver:id,name,phone,wallet_balance')->latest()->get(),
        ]);
    }

    public function approveWithdrawal(DriverWithdrawal $driverWithdrawal): RedirectResponse
    {
        if ($driverWithdrawal->status !== 'pending') return back()->withErrors(['status' => 'تمت مراجعة طلب السحب مسبقًا.']);
        $driverWithdrawal->update(['status' => 'paid', 'reviewed_by' => auth()->id(), 'reviewed_at' => now()]);
        app(FirebaseRealtimeService::class)->syncWithdrawal($driverWithdrawal->fresh());
        return back()->with('status', 'تم اعتماد طلب السحب وتحويله إلى مدفوع.');
    }

    public function rejectWithdrawal(DriverWithdrawal $driverWithdrawal): RedirectResponse
    {
        DB::transaction(function () use ($driverWithdrawal): void {
            $withdrawal = DriverWithdrawal::query()->lockForUpdate()->findOrFail($driverWithdrawal->id);
            if ($withdrawal->status !== 'pending') return;
            User::query()->lockForUpdate()->findOrFail($withdrawal->driver_id)->increment('wallet_balance', $withdrawal->amount);
            $withdrawal->update(['status' => 'rejected', 'reviewed_by' => auth()->id(), 'reviewed_at' => now()]);
        });
        app(FirebaseRealtimeService::class)->syncWithdrawal($driverWithdrawal->fresh());
        return back()->with('status', 'تم رفض طلب السحب وإعادة المبلغ لمحفظة السائق.');
    }

    public function storePaymentAccount(Request $request): RedirectResponse
    {
        $data = $this->validatePaymentAccount($request);

        if (blank($data['account_number'] ?? null) && blank($data['phone_number'] ?? null)) {
            return back()
                ->withErrors(['account_number' => 'أدخل رقم الحساب أو رقم الجوال على الأقل.'])
                ->withInput();
        }

        WalletPaymentAccount::create([
            ...$data,
            'is_active' => true,
            'sort_order' => $data['sort_order'] ?? 0,
        ]);

        return back()->with('status', 'تمت إضافة طريقة الدفع وستظهر للركاب في المحفظة.');
    }

    public function updatePaymentAccount(Request $request, WalletPaymentAccount $walletPaymentAccount): RedirectResponse
    {
        $data = $this->validatePaymentAccount($request);

        if (blank($data['account_number'] ?? null) && blank($data['phone_number'] ?? null)) {
            return back()
                ->withErrors(['account_number' => 'أدخل رقم الحساب أو رقم الجوال على الأقل.'])
                ->withInput();
        }

        $walletPaymentAccount->update([
            ...$data,
            'is_active' => $request->boolean('is_active'),
            'sort_order' => $data['sort_order'] ?? 0,
        ]);

        return back()->with('status', 'تم تحديث حساب التحويل.');
    }

    public function togglePaymentAccount(WalletPaymentAccount $walletPaymentAccount): RedirectResponse
    {
        $walletPaymentAccount->update([
            'is_active' => ! $walletPaymentAccount->is_active,
        ]);

        return back()->with('status', 'تم تحديث حالة طريقة الدفع.');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'amount' => ['required', 'numeric', 'min:1'],
            'bank_name' => ['required', 'string', 'max:255'],
            'reference_number' => ['nullable', 'string', 'max:255', 'unique:wallet_deposits,reference_number'],
            'receipt_image' => ['required', 'image', 'max:5120'],
            'note' => ['nullable', 'string', 'max:5000'],
        ]);

        $path = $request->file('receipt_image')->store('wallet-deposits', 'public');

        WalletDeposit::create([
            'user_id' => $data['user_id'],
            'amount' => $data['amount'],
            'bank_name' => $data['bank_name'],
            'reference_number' => $data['reference_number'] ?? null,
            'receipt_path' => $path,
            'status' => 'pending',
            'note' => $data['note'] ?? null,
        ]);

        return back()->with('status', 'تم حفظ إشعار الإيداع بانتظار الاعتماد.');
    }

    public function approve(Request $request, WalletDeposit $walletDeposit): RedirectResponse
    {
        if (! $walletDeposit->isPending()) {
            return back()->withErrors(['status' => 'تمت مراجعة هذا الإشعار مسبقًا، حدّث الصفحة لمشاهدة الحالة الحالية.']);
        }

        $data = $request->validate([
            'approved_amount' => ['nullable', 'numeric', 'min:1'],
        ]);

        $approved = false;

        DB::transaction(function () use ($walletDeposit, $data, &$approved): void {
            $walletDeposit = WalletDeposit::query()
                ->lockForUpdate()
                ->findOrFail($walletDeposit->id);

            if (! $walletDeposit->isPending()) {
                return;
            }

            $approvedAmount = $data['approved_amount'] ?? $walletDeposit->amount;
            $user = User::query()->lockForUpdate()->findOrFail($walletDeposit->user_id);

            $user->increment('wallet_balance', $approvedAmount);

            $walletDeposit->update([
                'amount' => $approvedAmount,
                'status' => 'approved',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'wallet_credited_at' => now(),
            ]);

            $approved = true;
        });

        if (! $approved) {
            return back()->withErrors(['status' => 'تمت مراجعة هذا الإشعار من صفحة أخرى، حدّث الصفحة قبل المتابعة.']);
        }

        return back()->with('status', 'تم اعتماد الإشعار وإضافة الرصيد إلى المحفظة.');
    }

    public function reject(WalletDeposit $walletDeposit): RedirectResponse
    {
        if (! $walletDeposit->isPending()) {
            return back()->withErrors(['status' => 'تمت مراجعة هذا الإشعار مسبقًا، حدّث الصفحة لمشاهدة الحالة الحالية.']);
        }

        $rejected = false;

        DB::transaction(function () use ($walletDeposit, &$rejected): void {
            $walletDeposit = WalletDeposit::query()
                ->lockForUpdate()
                ->findOrFail($walletDeposit->id);

            if (! $walletDeposit->isPending()) {
                return;
            }

            $walletDeposit->update([
                'status' => 'rejected',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'wallet_credited_at' => null,
            ]);

            $rejected = true;
        });

        if (! $rejected) {
            return back()->withErrors(['status' => 'تمت مراجعة هذا الإشعار من صفحة أخرى، حدّث الصفحة قبل المتابعة.']);
        }

        return back()->with('status', 'تم رفض إشعار الإيداع.');
    }

    private function validatePaymentAccount(Request $request): array
    {
        return $request->validate([
            'type' => ['required', Rule::in(['bank', 'mobile_wallet', 'other'])],
            'name' => ['required', 'string', 'max:255'],
            'account_holder_name' => ['required', 'string', 'max:255'],
            'account_number' => ['nullable', 'string', 'max:255'],
            'phone_number' => ['nullable', 'string', 'max:30'],
            'instructions' => ['nullable', 'string', 'max:5000'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);
    }
}
