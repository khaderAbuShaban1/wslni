<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>فاتورة {{ $account->name }}</title>
    <style>
        :root {
            --text: #111214;
            --muted: #747880;
            --line: #e7dfcf;
            --primary: #e9b934;
            --soft: #fcfaf4;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #f5f2ea;
            color: var(--text);
        }
        .page {
            max-width: 960px;
            margin: 24px auto;
            padding: 24px;
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 18px;
            box-shadow: 0 18px 48px rgba(103, 99, 91, 0.12);
        }
        .topbar,
        .row,
        .actions {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }
        .brand {
            display: grid;
            gap: 4px;
        }
        h1,
        h2,
        p {
            margin: 0;
        }
        h1 {
            font-size: 28px;
        }
        h2 {
            font-size: 18px;
            margin-bottom: 10px;
        }
        .muted {
            color: var(--muted);
            line-height: 1.7;
        }
        .badge {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 7px 12px;
            background: #fff3cf;
            color: #6f5200;
            font-weight: 800;
        }
        .section {
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid var(--line);
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
            gap: 12px;
        }
        .box {
            padding: 14px;
            background: var(--soft);
            border: 1px solid var(--line);
            border-radius: 14px;
        }
        .label {
            color: var(--muted);
            font-size: 12px;
            margin-bottom: 6px;
        }
        .value {
            font-weight: 900;
            line-height: 1.5;
            word-break: break-word;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
        }
        th,
        td {
            padding: 12px 10px;
            border-bottom: 1px solid var(--line);
            text-align: right;
            vertical-align: top;
            font-size: 14px;
        }
        th {
            color: var(--muted);
            background: var(--soft);
        }
        .btn {
            border: 1px solid var(--line);
            background: #fff;
            color: var(--text);
            border-radius: 12px;
            padding: 10px 14px;
            font: inherit;
            text-decoration: none;
            cursor: pointer;
        }
        .btn.primary {
            background: var(--primary);
            color: #211a00;
            border-color: var(--primary);
        }
        @media print {
            body { background: #fff; }
            .page {
                max-width: none;
                margin: 0;
                border: 0;
                box-shadow: none;
                border-radius: 0;
            }
            .actions { display: none; }
        }
    </style>
</head>
<body>
@php
    $typeLabel = match ($account->type) {
        'bank' => 'حساب بنكي',
        'mobile_wallet' => 'محفظة إلكترونية',
        default => 'طريقة أخرى',
    };

    $statusLabel = fn (string $status): string => match ($status) {
        'approved' => 'معتمد',
        'rejected' => 'مرفوض',
        default => 'بانتظار المراجعة',
    };
@endphp

<main class="page">
    <div class="topbar">
        <div class="brand">
            <span class="badge">Wslni</span>
            <h1>فاتورة طريقة دفع</h1>
            <p class="muted">فاتورة قابلة للطباعة لبيانات التحويل والإيداعات المرتبطة بهذه الطريقة.</p>
        </div>
        <div>
            <div class="label">رقم الفاتورة</div>
            <div class="value">{{ $account->invoiceNumber() }}</div>
            <div class="muted">{{ now()->format('Y-m-d H:i') }}</div>
        </div>
    </div>

    <div class="actions section">
        <a class="btn" href="{{ route('admin.wallet-payment-accounts.index') }}">العودة لحسابات التحويل</a>
        <button class="btn primary" type="button" onclick="window.print()">طباعة / حفظ PDF</button>
    </div>

    <section class="section">
        <h2>بيانات طريقة الدفع</h2>
        <div class="grid">
            <div class="box">
                <div class="label">اسم الطريقة</div>
                <div class="value">{{ $account->name }}</div>
            </div>
            <div class="box">
                <div class="label">النوع</div>
                <div class="value">{{ $typeLabel }}</div>
            </div>
            <div class="box">
                <div class="label">صاحب الحساب</div>
                <div class="value">{{ $account->account_holder_name }}</div>
            </div>
            <div class="box">
                <div class="label">الحالة</div>
                <div class="value">{{ $account->is_active ? 'نشط' : 'متوقف' }}</div>
            </div>
            @if ($account->account_number)
                <div class="box">
                    <div class="label">رقم الحساب / IBAN</div>
                    <div class="value">{{ $account->account_number }}</div>
                </div>
            @endif
            @if ($account->phone_number)
                <div class="box">
                    <div class="label">رقم الجوال / المحفظة</div>
                    <div class="value">{{ $account->phone_number }}</div>
                </div>
            @endif
        </div>
        @if ($account->instructions)
            <p class="muted" style="margin-top:12px;">{{ $account->instructions }}</p>
        @endif
    </section>

    <section class="section">
        <h2>ملخص الإيداعات</h2>
        <div class="grid">
            <div class="box">
                <div class="label">كل الإشعارات</div>
                <div class="value">{{ $totalDeposits }}</div>
            </div>
            <div class="box">
                <div class="label">بانتظار المراجعة</div>
                <div class="value">{{ $pendingDeposits }}</div>
            </div>
            <div class="box">
                <div class="label">معتمدة</div>
                <div class="value">{{ $approvedDeposits }}</div>
            </div>
            <div class="box">
                <div class="label">مرفوضة</div>
                <div class="value">{{ $rejectedDeposits }}</div>
            </div>
            <div class="box">
                <div class="label">إجمالي المعتمد</div>
                <div class="value">{{ number_format((float) $approvedTotal, 2) }} ₪</div>
            </div>
        </div>
    </section>

    <section class="section">
        <h2>آخر إشعارات الإيداع</h2>
        @if ($deposits->isEmpty())
            <p class="muted">لا توجد إشعارات مرتبطة بهذه الطريقة بعد.</p>
        @else
            <table>
                <thead>
                    <tr>
                        <th>الراكب</th>
                        <th>المبلغ</th>
                        <th>المرجع</th>
                        <th>الحالة</th>
                        <th>التاريخ</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($deposits as $deposit)
                        <tr>
                            <td>
                                <strong>{{ $deposit->user?->name }}</strong>
                                <div class="muted">{{ $deposit->user?->phone ?? $deposit->user?->email }}</div>
                            </td>
                            <td>{{ number_format((float) $deposit->amount, 2) }} ₪</td>
                            <td>{{ $deposit->reference_number ?? 'بدون مرجع' }}</td>
                            <td>{{ $statusLabel($deposit->status) }}</td>
                            <td>{{ optional($deposit->created_at)->format('Y-m-d H:i') }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </section>
</main>
</body>
</html>
