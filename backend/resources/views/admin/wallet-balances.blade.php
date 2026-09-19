@extends('admin.layout', ['title' => 'أرصدة المستخدمين'])

@section('content')
    <div class="header">
        <div>
            <h1>أرصدة المستخدمين</h1>
            <p class="subtitle">الرصيد الحالي لكل راكب وسائق، مرتبًا من الأعلى، مع بحث بالاسم أو الهاتف أو البريد.</p>
        </div>
    </div>

    @include('admin.partials.wallet-nav', ['active' => 'balances'])

    <section class="summary">
        <div class="metric"><div class="label">إجمالي الأرصدة</div><div class="value">{{ number_format($totalBalances, 2) }} ₪</div><div class="hint">مجموع كل المحافظ</div></div>
        <div class="metric"><div class="label">أرصدة الركاب</div><div class="value">{{ number_format($customerBalances, 2) }} ₪</div><div class="hint">متاحة لدفع الرحلات</div></div>
        <div class="metric"><div class="label">أرصدة السائقين</div><div class="value">{{ number_format($driverBalances, 2) }} ₪</div><div class="hint">متاحة للسحب</div></div>
        <div class="metric"><div class="label">في العرض</div><div class="value">{{ $users->count() }}</div><div class="hint">حساب ضمن النتائج</div></div>
    </section>

    <div class="panel" style="margin-top:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>قائمة الأرصدة</h2>
                    <p>أعلى 200 رصيد. استخدم البحث للوصول إلى حساب بعينه.</p>
                </div>
                <form class="controls" method="get" action="{{ route('admin.wallets.balances') }}">
                    <label class="search" style="min-width:min(100%, 300px);">
                        <span>بحث</span>
                        <input type="search" name="search" value="{{ $search }}" placeholder="الاسم، البريد أو رقم الهاتف">
                    </label>
                    <button class="btn primary" type="submit">تصفية</button>
                    <a class="btn" href="{{ route('admin.wallets.balances') }}">إعادة ضبط</a>
                </form>
            </div>
        </div>

        @if ($users->isEmpty())
            <div class="empty">لا توجد حسابات مطابقة.</div>
        @else
            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>الحساب</th>
                            <th>بيانات التواصل</th>
                            <th>الدور</th>
                            <th>الرصيد</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($users as $user)
                            <tr>
                                <td>
                                    <div class="person">
                                        @include('admin.partials.avatar', ['user' => $user, 'size' => 34])
                                        <strong>{{ $user->name }}</strong>
                                    </div>
                                </td>
                                <td>
                                    <div class="muted">{{ $user->email }}</div>
                                    <div class="muted">{{ $user->phone }}</div>
                                </td>
                                <td>{{ $user->role === 'driver' ? 'سائق' : 'راكب' }}</td>
                                <td><strong>{{ number_format((float) $user->wallet_balance, 2) }} ₪</strong></td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
@endsection
