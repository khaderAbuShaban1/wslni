@extends('admin.layout', ['title' => 'حسابات التحويل'])

@section('content')
    <div class="header">
        <div>
            <h1>حسابات التحويل</h1>
            <p class="subtitle">أضف الحسابات البنكية أو المحافظ الإلكترونية التي تظهر للكستمر عند شحن المحفظة ورفع إشعار الدفع.</p>
        </div>
        <div class="topline">
            <a class="pill active" href="{{ route('admin.wallet-payment-accounts.index') }}">إدارة الحسابات</a>
            <a class="pill" href="{{ route('admin.wallets.index') }}">إشعارات المحافظ</a>
        </div>
    </div>

    <section class="summary">
        <div class="metric">
            <div class="label">كل الحسابات</div>
            <div class="value">{{ $paymentAccounts->count() }}</div>
            <div class="hint">حسابات التحويل المحفوظة في النظام</div>
        </div>
        <div class="metric">
            <div class="label">ظاهرة للكستمر</div>
            <div class="value">{{ $activeCount }}</div>
            <div class="hint">الحسابات النشطة فقط تظهر داخل التطبيق</div>
        </div>
        <div class="metric">
            <div class="label">متوقفة</div>
            <div class="value">{{ $inactiveCount }}</div>
            <div class="hint">يمكن تفعيلها مرة ثانية بدون حذفها</div>
        </div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>إضافة حساب تحويل</h2>
                        <p>اكتب بيانات الحساب كما تريد أن يراها الكستمر في شاشة شحن المحفظة.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.wallet-payment-accounts.store') }}" class="form-grid">
                    @csrf
                    <div class="form-row">
                        <label>نوع الحساب</label>
                        <select class="select" name="type" required>
                            <option value="bank" @selected(old('type') === 'bank')>حساب بنكي</option>
                            <option value="mobile_wallet" @selected(old('type') === 'mobile_wallet')>محفظة إلكترونية</option>
                            <option value="other" @selected(old('type') === 'other')>طريقة أخرى</option>
                        </select>
                    </div>
                    <div class="form-row">
                        <label>اسم الحساب الظاهر للكستمر</label>
                        <input class="input" name="name" value="{{ old('name') }}" required placeholder="بنك فلسطين">
                    </div>
                    <div class="form-row">
                        <label>اسم صاحب الحساب</label>
                        <input class="input" name="account_holder_name" value="{{ old('account_holder_name') }}" required placeholder="Wslni">
                    </div>
                    <div class="form-row">
                        <label>رقم الحساب / IBAN</label>
                        <input class="input" name="account_number" value="{{ old('account_number') }}" placeholder="اختياري للمحافظ">
                    </div>
                    <div class="form-row">
                        <label>رقم الجوال / المحفظة</label>
                        <input class="input" name="phone_number" value="{{ old('phone_number') }}" placeholder="059xxxxxxx">
                    </div>
                    <div class="form-row">
                        <label>ترتيب الظهور</label>
                        <input class="input" name="sort_order" type="number" min="0" value="{{ old('sort_order', 0) }}">
                    </div>
                    <div class="form-row" style="grid-column: 1 / -1;">
                        <label>تعليمات للكستمر</label>
                        <textarea class="textarea" name="instructions" rows="3" placeholder="حوّل المبلغ ثم ارفع صورة إشعار الدفع من التطبيق.">{{ old('instructions') }}</textarea>
                    </div>
                    <div class="form-row" style="grid-column: 1 / -1;">
                        <button class="btn primary" type="submit">إضافة الحساب</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>ملاحظة الظهور في التطبيق</h2>
                        <p>بعد الإضافة سيظهر الحساب فورًا للكستمر في شاشة المحفظة إذا كان نشطًا. الحسابات المتوقفة تبقى محفوظة لكنها لا تظهر في التطبيق.</p>
                    </div>
                </div>
            </div>
            <div class="list">
                <div class="list-item">
                    <div>
                        <strong>للحساب البنكي</strong>
                        <small>استخدم رقم الحساب أو IBAN، ويمكن إضافة تعليمات خاصة للبنك.</small>
                    </div>
                </div>
                <div class="list-item">
                    <div>
                        <strong>للمحفظة الإلكترونية</strong>
                        <small>استخدم رقم الجوال أو رقم المحفظة مثل Jawwal Pay أو PalPay.</small>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <div class="panel" style="margin-top:16px;">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>الحسابات الحالية</h2>
                    <p>عدّل البيانات أو أوقف الحساب مؤقتًا إذا لم يعد متاحًا للتحويل.</p>
                </div>
            </div>
        </div>

        @if ($paymentAccounts->isEmpty())
            <div class="empty">لا توجد حسابات تحويل بعد.</div>
        @else
            <div class="list">
                @foreach ($paymentAccounts as $account)
                    <div class="list-item" style="align-items:flex-start;">
                        <div style="flex:1 1 520px;">
                            <strong>{{ $account->name }}</strong>
                            <small>{{ $account->account_holder_name }}</small>
                            @if ($account->account_number)
                                <small>رقم الحساب: {{ $account->account_number }}</small>
                            @endif
                            @if ($account->phone_number)
                                <small>رقم الجوال: {{ $account->phone_number }}</small>
                            @endif
                            @if ($account->instructions)
                                <small>{{ $account->instructions }}</small>
                            @endif

                            <details style="margin-top:12px;">
                                <summary class="btn" style="width:max-content;">تعديل البيانات</summary>
                                <form method="post" action="{{ route('admin.wallet-payment-accounts.update', $account) }}" class="form-grid" style="margin-top:12px;">
                                    @csrf
                                    @method('patch')
                                    <input type="hidden" name="is_active" value="0">
                                    <div class="form-row">
                                        <label>نوع الحساب</label>
                                        <select class="select" name="type" required>
                                            <option value="bank" @selected($account->type === 'bank')>حساب بنكي</option>
                                            <option value="mobile_wallet" @selected($account->type === 'mobile_wallet')>محفظة إلكترونية</option>
                                            <option value="other" @selected($account->type === 'other')>طريقة أخرى</option>
                                        </select>
                                    </div>
                                    <div class="form-row">
                                        <label>اسم الحساب</label>
                                        <input class="input" name="name" value="{{ $account->name }}" required>
                                    </div>
                                    <div class="form-row">
                                        <label>صاحب الحساب</label>
                                        <input class="input" name="account_holder_name" value="{{ $account->account_holder_name }}" required>
                                    </div>
                                    <div class="form-row">
                                        <label>رقم الحساب</label>
                                        <input class="input" name="account_number" value="{{ $account->account_number }}">
                                    </div>
                                    <div class="form-row">
                                        <label>رقم الجوال</label>
                                        <input class="input" name="phone_number" value="{{ $account->phone_number }}">
                                    </div>
                                    <div class="form-row">
                                        <label>ترتيب الظهور</label>
                                        <input class="input" name="sort_order" type="number" min="0" value="{{ $account->sort_order }}">
                                    </div>
                                    <div class="form-row" style="grid-column: 1 / -1;">
                                        <label>تعليمات للكستمر</label>
                                        <textarea class="textarea" name="instructions" rows="3">{{ $account->instructions }}</textarea>
                                    </div>
                                    <label class="form-row" style="grid-column: 1 / -1;">
                                        <span>الظهور للكستمر</span>
                                        <span>
                                            <input type="checkbox" name="is_active" value="1" @checked($account->is_active)>
                                            حساب نشط ويظهر في التطبيق
                                        </span>
                                    </label>
                                    <div class="form-row" style="grid-column: 1 / -1;">
                                        <button class="btn primary" type="submit">حفظ التعديل</button>
                                    </div>
                                </form>
                            </details>
                        </div>
                        <div class="table-actions">
                            <span class="status {{ $account->is_active ? 'approved' : 'rejected' }}">{{ $account->is_active ? 'نشط' : 'متوقف' }}</span>
                            <a class="btn blue" href="{{ route('admin.wallet-payment-accounts.invoice', $account) }}" target="_blank">استخراج فاتورة</a>
                            <form method="post" action="{{ route('admin.wallet-payment-accounts.toggle', $account) }}">
                                @csrf
                                @method('patch')
                                <button class="btn" type="submit">{{ $account->is_active ? 'إيقاف' : 'تفعيل' }}</button>
                            </form>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
@endsection
