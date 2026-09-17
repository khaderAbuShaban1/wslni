@extends('admin.layout', ['title' => 'المحافظ'])

@section('content')
    <div class="header">
        <div>
            <h1>إشعارات الإيداع</h1>
            <p class="subtitle">استقبل إشعارات التحويل البنكي، راجع الصور، ثم اعتمد المبلغ ليُضاف مباشرة إلى محفظة الراكب.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'الكل', 'pending' => 'بانتظار المراجعة', 'approved' => 'معتمدة', 'rejected' => 'مرفوضة'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.wallets.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    @include('admin.partials.wallet-nav', ['active' => 'deposits'])

    <div class="panel" style="margin-bottom:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>طابور إشعارات الدفع</h2>
                    <p>كل صف يمثل طلبًا مستقلًا برقم واضح وبيانات الكستمر؛ راجع الإشعار ثم اعتمد أو ارفض بدون خلط بين الطلبات.</p>
                </div>
                <span class="count-badge">{{ $pendingDeposits->count() }} معلّق</span>
            </div>
        </div>

        @if ($pendingDeposits->isEmpty())
            <div class="empty">لا توجد إشعارات دفع بانتظار الموافقة الآن.</div>
        @else
            <div class="scroll-y" style="overflow-x:auto;">
                <table>
                    <thead>
                        <tr>
                            <th>الطلب</th>
                            <th>الكستمر</th>
                            <th>المبلغ والرصيد</th>
                            <th>طريقة الدفع</th>
                            <th>الإشعار</th>
                            <th>قرار المراجعة</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($pendingDeposits as $deposit)
                            @php
                                $customerPendingCount = $pendingCustomerCounts[$deposit->user_id] ?? 0;
                            @endphp
                            <tr>
                                <td>
                                    <strong>طلب #{{ $deposit->id }}</strong>
                                    <div class="muted">{{ optional($deposit->created_at)->format('Y-m-d H:i') }}</div>
                                    <span class="status pending" style="margin-top:8px;">بانتظار المراجعة</span>
                                </td>
                                <td>
                                    <strong>{{ $deposit->user?->name }}</strong>
                                    <div class="muted">{{ $deposit->user?->phone }}</div>
                                    <div class="muted">{{ $deposit->user?->email }}</div>
                                    @if ($customerPendingCount > 1)
                                        <span class="status pending" style="margin-top:8px;">له {{ $customerPendingCount }} طلبات معلقة</span>
                                    @endif
                                </td>
                                <td>
                                    <strong>{{ number_format((float) $deposit->amount, 2) }} ₪</strong>
                                    <div class="muted">رصيده الحالي: {{ number_format((float) ($deposit->user?->wallet_balance ?? 0), 2) }} ₪</div>
                                </td>
                                <td>
                                    <strong>{{ $deposit->paymentAccount?->name ?? $deposit->bank_name }}</strong>
                                    @if ($deposit->paymentAccount)
                                        <div class="muted">{{ $deposit->paymentAccount->account_holder_name }}</div>
                                    @endif
                                    <div class="muted">مرجع: {{ $deposit->reference_number ?? 'بدون مرجع' }}</div>
                                    @if ($deposit->note)
                                        <div class="muted">ملاحظة: {{ $deposit->note }}</div>
                                    @endif
                                </td>
                                <td>
                                    @if ($deposit->receipt_path)
                                        <a href="{{ route('admin.wallets.receipt', $deposit) }}" target="_blank" rel="noopener noreferrer" style="display:inline-block; margin-bottom:8px;">
                                            <img src="{{ route('admin.wallets.receipt', $deposit) }}" alt="صورة إشعار طلب #{{ $deposit->id }}" style="width:96px; height:64px; object-fit:contain; border:1px solid var(--line); border-radius:12px; background:#f8fafc;">
                                        </a>
                                        <br>
                                        <a href="{{ route('admin.wallets.receipt', $deposit) }}" target="_blank" rel="noopener noreferrer" class="btn">فتح الصورة</a>
                                    @else
                                        <div class="muted">لا توجد صورة مرفقة.</div>
                                    @endif
                                </td>
                                <td>
                                    <div style="display:grid; gap:8px; min-width:220px;">
                                        <form method="post" action="{{ route('admin.wallets.approve', $deposit) }}" style="display:grid; gap:8px;" onsubmit="return confirm('اعتماد طلب #{{ $deposit->id }} وإضافة الرصيد؟')">
                                            @csrf
                                            @method('patch')
                                            <input class="input" name="approved_amount" type="number" step="0.01" min="1" value="{{ $deposit->amount }}" aria-label="مبلغ اعتماد طلب #{{ $deposit->id }}" required>
                                            <button class="btn blue" type="submit">اعتماد طلب #{{ $deposit->id }}</button>
                                        </form>
                                        <form method="post" action="{{ route('admin.wallets.reject', $deposit) }}" onsubmit="return confirm('رفض طلب #{{ $deposit->id }}؟')">
                                            @csrf
                                            @method('patch')
                                            <button class="btn danger" type="submit" style="width:100%;">رفض طلب #{{ $deposit->id }}</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>

    <section class="summary">
        <div class="metric"><div class="label">الإيداعات المعتمدة</div><div class="value">{{ $approvedCount }}</div><div class="hint">{{ number_format((float) $totalCredited, 2) }} ₪ تم إضافتها</div></div>
        <div class="metric"><div class="label">بانتظار المراجعة</div><div class="value">{{ $pendingCount }}</div><div class="hint">تنتظر اعتمادًا أو رفضًا</div></div>
        <div class="metric"><div class="label">مرفوضة</div><div class="value">{{ $rejectedCount }}</div><div class="hint">إشعارات لم تُعتمد</div></div>
    </section>

    <section>
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>إضافة إشعار إيداع</h2>
                        <p>ارفع صورة إشعار الحوالة البنكية وحدد الراكب والمبلغ، ثم اعتمد العملية من نفس اللوحة.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.wallets.store') }}" class="form-grid" enctype="multipart/form-data">
                    @csrf
                    <div class="form-row">
                        <label>الراكب</label>
                        <select class="select" name="user_id" required>
                            @foreach ($users as $user)
                                <option value="{{ $user->id }}">{{ $user->name }} - {{ number_format((float) $user->wallet_balance, 2) }} ₪</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-row">
                        <label>المبلغ</label>
                        <input class="input" name="amount" type="number" step="0.01" min="1" required placeholder="0.00">
                    </div>
                    <div class="form-row">
                        <label>اسم البنك</label>
                        <input class="input" name="bank_name" required placeholder="بنك فلسطين">
                    </div>
                    <div class="form-row">
                        <label>رقم المرجع</label>
                        <input class="input" name="reference_number" placeholder="REF-2026-001">
                    </div>
                    <div class="form-row">
                        <label>صورة الإشعار</label>
                        <input class="input" name="receipt_image" type="file" accept="image/*" required>
                    </div>
                    <div class="form-row">
                        <label>ملاحظة</label>
                        <input class="input" name="note" placeholder="اختياري">
                    </div>
                    <div class="form-row" style="grid-column: 1 / -1;">
                        <button class="btn primary" type="submit">حفظ إشعار الإيداع</button>
                    </div>
                </form>
            </div>
        </div>

    </section>

    <div class="panel" style="margin-top:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>إشعارات الإيداع الأخيرة</h2>
                    <p>راجع الصور والحالة ثم اعتمد الإيداع ليُضاف الرصيد تلقائيًا.</p>
                </div>
                <form class="controls" method="get" action="{{ route('admin.wallets.index') }}">
                    <input type="hidden" name="status" value="{{ $status }}">
                    <label class="search" style="min-width:min(100%, 320px);">
                        <span>بحث</span>
                        <input type="search" name="search" value="{{ $search }}" placeholder="رقم الطلب، المرجع، البنك، اسم الراكب، الهاتف أو البريد">
                    </label>
                    <button class="btn primary" type="submit">تصفية</button>
                    <a class="btn" href="{{ route('admin.wallets.index') }}">إعادة ضبط</a>
                </form>
            </div>
        </div>

        @if ($deposits->isEmpty())
            <div class="empty">لا توجد إشعارات إيداع بعد.</div>
        @else
            <div class="scroll-y" style="max-height:520px; overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>الطلب</th>
                        <th>الراكب</th>
                        <th>التحويل</th>
                        <th>الإشعار</th>
                        <th>الحالة</th>
                        <th>الإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($deposits as $deposit)
                        <tr>
                            <td>
                                <strong>#{{ $deposit->id }}</strong>
                                <div class="muted">{{ optional($deposit->created_at)->format('Y-m-d H:i') }}</div>
                            </td>
                            <td>
                                <strong>{{ $deposit->user?->name }}</strong>
                                <div class="muted">{{ $deposit->user?->email }}</div>
                                <div class="muted">الرصيد الحالي: {{ number_format((float) ($deposit->user?->wallet_balance ?? 0), 2) }} ₪</div>
                            </td>
                            <td>
                                <strong>{{ number_format((float) $deposit->amount, 2) }} ₪</strong>
                                <div class="muted">{{ $deposit->paymentAccount?->name ?? $deposit->bank_name }}</div>
                                @if ($deposit->paymentAccount)
                                    <div class="muted">{{ $deposit->paymentAccount->account_holder_name }}</div>
                                @endif
                                <div class="muted">{{ $deposit->reference_number ?? 'بدون مرجع' }}</div>
                            </td>
                            <td>
                                @if ($deposit->receipt_path)
                                    <a href="{{ route('admin.wallets.receipt', $deposit) }}" target="_blank" rel="noopener noreferrer" class="btn" style="margin-bottom:8px;">فتح الصورة</a>
                                    <div class="muted">{{ $deposit->note ?? 'لا توجد ملاحظة' }}</div>
                                @else
                                    <div class="muted">لا توجد صورة مرفقة.</div>
                                @endif
                            </td>
                            <td>
                                <span class="status {{ $deposit->status }}">{{ $deposit->status === 'approved' ? 'معتمد' : ($deposit->status === 'rejected' ? 'مرفوض' : 'بانتظار المراجعة') }}</span>
                                <div class="muted" style="margin-top:8px;">
                                    {{ optional($deposit->reviewed_at)->format('M d, H:i') ?? 'لم يراجع بعد' }}
                                </div>
                            </td>
                            <td>
                                @if ($deposit->status === 'pending')
                                    <div class="table-actions">
                                        <form method="post" action="{{ route('admin.wallets.approve', $deposit) }}" style="display:grid; gap:8px; min-width:150px;">
                                            @csrf
                                            @method('patch')
                                            <input class="input" name="approved_amount" type="number" step="0.01" min="1" value="{{ $deposit->amount }}" required>
                                            <button class="btn blue" type="submit">اعتماد وإيداع</button>
                                        </form>
                                        <form method="post" action="{{ route('admin.wallets.reject', $deposit) }}">
                                            @csrf
                                            @method('patch')
                                            <button class="btn danger" type="submit">رفض</button>
                                        </form>
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
