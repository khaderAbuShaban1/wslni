@extends('admin.layout', ['title' => 'طلبات السحب'])

@section('content')
    <div class="header">
        <div>
            <h1>طلبات السحب</h1>
            <p class="subtitle">راجع بيانات التحويل للسائق ثم اعتمد الطلب أو ارفضه لإعادة المبلغ إلى محفظته.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'الكل', 'pending' => 'بانتظار المراجعة', 'paid' => 'مدفوعة', 'rejected' => 'مرفوضة'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.wallets.withdrawals', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    @include('admin.partials.wallet-nav', ['active' => 'withdrawals'])

    <section class="summary">
        <div class="metric"><div class="label">بانتظار المراجعة</div><div class="value">{{ $pendingCount }}</div><div class="hint">تحتاج قرارًا الآن</div></div>
        <div class="metric"><div class="label">مدفوعة</div><div class="value">{{ $paidCount }}</div><div class="hint">{{ number_format($paidTotal, 2) }} ₪ تم تحويلها</div></div>
        <div class="metric"><div class="label">مرفوضة</div><div class="value">{{ $rejectedCount }}</div><div class="hint">أُعيد المبلغ للمحفظة</div></div>
        <div class="metric"><div class="label">الفلتر الحالي</div><div class="value">{{ ['all' => 'الكل', 'pending' => 'بانتظار المراجعة', 'paid' => 'مدفوعة', 'rejected' => 'مرفوضة'][$status] ?? $status }}</div><div class="hint">نطاق القائمة</div></div>
    </section>

    <div class="panel" style="margin-top:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>طابور طلبات السحب</h2>
                    <p>الطلبات المعلّقة تظهر أولًا. الاعتماد يحوّل الطلب إلى مدفوع، والرفض يعيد المبلغ إلى محفظة السائق.</p>
                </div>
                <form class="controls" method="get" action="{{ route('admin.wallets.withdrawals') }}">
                    <input type="hidden" name="status" value="{{ $status }}">
                    <label class="search" style="min-width:min(100%, 280px);">
                        <span>بحث</span>
                        <input type="search" name="search" value="{{ $search }}" placeholder="اسم السائق أو رقم الهاتف">
                    </label>
                    <button class="btn primary" type="submit">تصفية</button>
                    <a class="btn" href="{{ route('admin.wallets.withdrawals') }}">إعادة ضبط</a>
                </form>
            </div>
        </div>

        @if ($withdrawals->isEmpty())
            <div class="empty">لا توجد طلبات سحب مطابقة.</div>
        @else
            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>السائق</th>
                            <th>المبلغ</th>
                            <th>وجهة التحويل</th>
                            <th>الحالة</th>
                            <th>الإجراء</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($withdrawals as $withdrawal)
                            <tr>
                                <td>
                                    <div class="person">
                                        @include('admin.partials.avatar', ['user' => $withdrawal->driver, 'size' => 34])
                                        <strong>{{ $withdrawal->driver?->name ?? 'سائق محذوف' }}</strong>
                                    </div>
                                    <div class="muted">{{ $withdrawal->driver?->phone }}</div>
                                    <div class="muted">{{ optional($withdrawal->created_at)->format('Y-m-d H:i') }}</div>
                                </td>
                                <td><strong>{{ number_format((float) $withdrawal->amount, 2) }} ₪</strong></td>
                                <td>
                                    {{ $withdrawal->method === 'bank' ? 'حساب بنكي' : 'محفظة جوال' }}
                                    <div class="muted">{{ $withdrawal->account_name }}</div>
                                    <div class="muted">{{ $withdrawal->account_number }}</div>
                                </td>
                                <td>
                                    <span class="status {{ $withdrawal->status }}">{{ $withdrawal->status === 'paid' ? 'مدفوع' : ($withdrawal->status === 'rejected' ? 'مرفوض' : 'بانتظار المراجعة') }}</span>
                                </td>
                                <td>
                                    @if ($withdrawal->status === 'pending')
                                        <div class="table-actions">
                                            <form method="post" action="{{ route('admin.driver-withdrawals.approve', $withdrawal) }}" onsubmit="return confirm('تأكيد تحويل {{ number_format((float) $withdrawal->amount, 2) }} ₪؟')">@csrf @method('patch')<button class="btn blue">تم التحويل</button></form>
                                            <form method="post" action="{{ route('admin.driver-withdrawals.reject', $withdrawal) }}" onsubmit="return confirm('رفض الطلب وإعادة المبلغ للمحفظة؟')">@csrf @method('patch')<button class="btn danger">رفض وإرجاع</button></form>
                                        </div>
                                    @else
                                        <div class="muted">تمت المراجعة، لا توجد إجراءات مطلوبة.</div>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>

    <div class="panel" style="margin-top:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>طلبات سحب الزبائن</h2>
                    <p>الزبون يسحب رصيد محفظته. المبلغ محجوز منذ الطلب، والرفض يعيده إلى محفظته.</p>
                </div>
                <span class="count-badge">{{ $customerWithdrawals->where('status', 'pending')->count() }} معلّق</span>
            </div>
        </div>

        @if ($customerWithdrawals->isEmpty())
            <div class="empty">لا توجد طلبات سحب من الزبائن.</div>
        @else
            <div style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>الزبون</th>
                            <th>المبلغ</th>
                            <th>وجهة التحويل</th>
                            <th>الحالة</th>
                            <th>الإجراء</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($customerWithdrawals as $withdrawal)
                            <tr>
                                <td>
                                    <div class="person">
                                        @include('admin.partials.avatar', ['user' => $withdrawal->customer, 'size' => 34])
                                        <strong>{{ $withdrawal->customer?->name ?? 'زبون محذوف' }}</strong>
                                    </div>
                                    <div class="muted">{{ $withdrawal->customer?->phone }}</div>
                                    <div class="muted">{{ optional($withdrawal->created_at)->format('Y-m-d H:i') }}</div>
                                </td>
                                <td><strong>{{ number_format((float) $withdrawal->amount, 2) }} ₪</strong></td>
                                <td>
                                    {{ $withdrawal->method === 'bank' ? 'حساب بنكي' : 'محفظة جوال' }}
                                    <div class="muted">{{ $withdrawal->account_name }}</div>
                                    <div class="muted">{{ $withdrawal->account_number }}</div>
                                </td>
                                <td>
                                    <span class="status {{ $withdrawal->status }}">{{ $withdrawal->status === 'paid' ? 'مدفوع' : ($withdrawal->status === 'rejected' ? 'مرفوض' : 'بانتظار المراجعة') }}</span>
                                </td>
                                <td>
                                    @if ($withdrawal->status === 'pending')
                                        <div class="table-actions">
                                            <form method="post" action="{{ route('admin.customer-withdrawals.approve', $withdrawal) }}" onsubmit="return confirm('تأكيد تحويل {{ number_format((float) $withdrawal->amount, 2) }} ₪؟')">@csrf @method('patch')<button class="btn blue">تم التحويل</button></form>
                                            <form method="post" action="{{ route('admin.customer-withdrawals.reject', $withdrawal) }}" onsubmit="return confirm('رفض الطلب وإعادة المبلغ للمحفظة؟')">@csrf @method('patch')<button class="btn danger">رفض وإرجاع</button></form>
                                        </div>
                                    @else
                                        <div class="muted">تمت المراجعة، لا توجد إجراءات مطلوبة.</div>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
@endsection
