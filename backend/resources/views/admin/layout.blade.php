<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'لوحة الإدارة' }}</title>
    <style>
        :root {
            --bg: #eef3f8;
            --panel: #ffffff;
            --panel-soft: #f8fbfd;
            --line: #d9e2ec;
            --line-strong: #c8d4e0;
            --text: #0f172a;
            --muted: #64748b;
            --primary: #0f766e;
            --primary-soft: #dff5f1;
            --accent: #1d4ed8;
            --accent-soft: #e8efff;
            --warning: #b45309;
            --warning-soft: #fff4e6;
            --danger: #b91c1c;
            --danger-soft: #fde8e8;
            --success: #166534;
            --success-soft: #e8f8ee;
            --shadow: 0 18px 48px rgba(15, 23, 42, 0.08);
        }
        * { box-sizing: border-box; }
        html { color-scheme: light; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                linear-gradient(180deg, rgba(15, 118, 110, 0.05) 0%, rgba(15, 118, 110, 0.01) 220px, transparent 220px),
                var(--bg);
            color: var(--text);
            direction: rtl;
            text-align: right;
        }
        a { color: inherit; }
        .shell {
            display: grid;
            grid-template-columns: 286px minmax(0, 1fr);
            min-height: 100vh;
        }
        .sidebar {
            position: sticky;
            top: 0;
            height: 100vh;
            overflow: auto;
            padding: 22px 18px;
            background: linear-gradient(180deg, #0f172a 0%, #111827 100%);
            color: #e5eef7;
            border-left: 1px solid rgba(255, 255, 255, 0.06);
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 8px 18px;
            margin-bottom: 8px;
            border-bottom: 1px solid rgba(148, 163, 184, 0.16);
        }
        .brand-mark {
            width: 44px;
            height: 44px;
            border-radius: 14px;
            background: linear-gradient(135deg, var(--primary) 0%, #10b981 100%);
            display: grid;
            place-items: center;
            color: #fff;
            font-weight: 800;
            box-shadow: 0 12px 30px rgba(15, 118, 110, 0.35);
            flex: 0 0 auto;
        }
        .brand strong {
            display: block;
            font-size: 15px;
            line-height: 1.3;
        }
        .brand span {
            display: block;
            margin-top: 3px;
            color: #9fb2c8;
            font-size: 12px;
        }
        .nav {
            display: grid;
            gap: 8px;
            margin-top: 16px;
        }
        .nav a {
            text-decoration: none;
            padding: 12px 14px;
            border-radius: 14px;
            color: #cbd5e1;
            background: rgba(255, 255, 255, 0.01);
            border: 1px solid transparent;
            transition: 160ms ease;
        }
        .nav a:hover {
            background: rgba(255, 255, 255, 0.04);
            border-color: rgba(148, 163, 184, 0.14);
            transform: translateY(-1px);
        }
        .nav a.active {
            color: #fff;
            background: rgba(15, 118, 110, 0.2);
            border-color: rgba(15, 118, 110, 0.38);
            box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.04);
        }
        .nav small {
            display: block;
            margin-top: 4px;
            color: #94a3b8;
            line-height: 1.5;
        }
        .userbox {
            margin-top: 22px;
            padding: 16px 0 0;
            border-top: 1px solid rgba(148, 163, 184, 0.18);
            display: grid;
            gap: 12px;
        }
        .userline strong { color: #fff; }
        .userline span {
            display: block;
            margin-top: 4px;
            color: #94a3b8;
            font-size: 13px;
            word-break: break-word;
        }
        .main {
            padding: 28px 22px 40px;
            min-width: 0;
        }
        .wrap {
            max-width: 1440px;
            margin: 0 auto;
        }
        .header {
            display: flex;
            gap: 16px;
            justify-content: space-between;
            align-items: flex-end;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0;
            font-size: 30px;
            line-height: 1.15;
            letter-spacing: 0;
        }
        .subtitle {
            margin: 8px 0 0;
            color: var(--muted);
            line-height: 1.7;
            max-width: 760px;
        }
        .topline {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 14px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.85);
            color: var(--muted);
            text-decoration: none;
            font-size: 14px;
            backdrop-filter: blur(10px);
        }
        .pill.active {
            border-color: transparent;
            background: var(--primary);
            color: #fff;
            box-shadow: 0 10px 24px rgba(15, 118, 110, 0.22);
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 14px;
            margin: 18px 0 18px;
        }
        .metric {
            background: linear-gradient(180deg, #fff 0%, #fcfeff 100%);
            border: 1px solid var(--line);
            border-radius: 16px;
            padding: 18px;
            box-shadow: 0 8px 24px rgba(15, 23, 42, 0.04);
        }
        .metric .label {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 8px;
        }
        .metric .value {
            font-size: 30px;
            font-weight: 800;
            line-height: 1.1;
            letter-spacing: 0;
        }
        .metric .hint {
            margin-top: 8px;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.6;
        }
        .panels {
            display: grid;
            grid-template-columns: minmax(0, 1.55fr) minmax(320px, 1fr);
            gap: 16px;
            align-items: start;
        }
        .panel {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: var(--shadow);
        }
        .panel-header {
            padding: 18px 20px 0;
        }
        .panel-title {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }
        .panel-title h2 {
            margin: 0;
            font-size: 18px;
            line-height: 1.3;
        }
        .panel-title p {
            margin: 6px 0 0;
            color: var(--muted);
            font-size: 14px;
            line-height: 1.7;
            max-width: 760px;
        }
        .controls {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 14px;
            padding-bottom: 16px;
        }
        .search {
            display: flex;
            align-items: center;
            gap: 8px;
            flex: 1 1 260px;
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 10px 12px;
            background: var(--panel-soft);
        }
        .search input,
        .input,
        .select,
        .textarea {
            border: 1px solid var(--line);
            outline: 0;
            width: 100%;
            font: inherit;
            background: #fff;
            border-radius: 14px;
            padding: 11px 12px;
            transition: border-color 120ms ease, box-shadow 120ms ease;
        }
        .search input {
            border: 0;
            padding: 0;
            background: transparent;
        }
        .search:focus-within,
        .input:focus,
        .select:focus,
        .textarea:focus {
            border-color: rgba(15, 118, 110, 0.45);
            box-shadow: 0 0 0 4px rgba(15, 118, 110, 0.12);
        }
        .btn {
            border: 1px solid var(--line);
            background: #fff;
            color: var(--text);
            border-radius: 14px;
            padding: 10px 14px;
            font: inherit;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            cursor: pointer;
            transition: 140ms ease;
        }
        .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 18px rgba(15, 23, 42, 0.06);
        }
        .btn.primary {
            background: var(--primary);
            color: #fff;
            border-color: var(--primary);
        }
        .btn.blue {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
        }
        .btn.danger {
            background: var(--danger);
            color: #fff;
            border-color: var(--danger);
        }
        .btn.ghost {
            background: transparent;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th,
        td {
            padding: 14px 18px;
            text-align: right;
            border-top: 1px solid var(--line);
            vertical-align: top;
            font-size: 14px;
        }
        th {
            color: var(--muted);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: .04em;
            background: #fbfdff;
        }
        tbody tr {
            transition: background-color 120ms ease;
        }
        tbody tr:hover {
            background: #fbfdff;
        }
        .status {
            display: inline-flex;
            align-items: center;
            padding: 6px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
        }
        .status.requested,
        .status.accepted,
        .status.arrived,
        .status.in_progress,
        .status.pending {
            background: var(--warning-soft);
            color: var(--warning);
        }
        .status.completed,
        .status.approved,
        .status.active,
        .status.resolved {
            background: var(--success-soft);
            color: var(--success);
        }
        .status.rejected,
        .status.suspended,
        .status.closed,
        .status.inactive,
        .status.open {
            background: #f1f5f9;
            color: #475569;
        }
        .status-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 74px;
            padding: 8px 10px;
            border-radius: 999px;
            background: var(--primary-soft);
            color: var(--primary);
            font-size: 12px;
            font-weight: 800;
        }
        .list {
            padding: 10px 18px 18px;
        }
        .list-item {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 14px 0;
            border-top: 1px solid var(--line);
        }
        .list-item:first-child { border-top: 0; }
        .list-item strong { display: block; margin-bottom: 5px; }
        .list-item small { color: var(--muted); line-height: 1.6; }
        .stack { display: grid; gap: 12px; margin-top: 16px; }
        .mini {
            border: 1px solid var(--line);
            border-radius: 16px;
            padding: 16px;
            background: linear-gradient(180deg, #fff 0%, #fcfeff 100%);
            box-shadow: 0 8px 24px rgba(15, 23, 42, 0.04);
        }
        .mini .label { font-size: 13px; color: var(--muted); }
        .mini .value { font-size: 24px; font-weight: 800; margin-top: 6px; }
        .mini .note { margin-top: 6px; color: var(--muted); font-size: 13px; line-height: 1.6; }
        .empty {
            padding: 24px 18px;
            color: var(--muted);
            border-top: 1px solid var(--line);
        }
        .alert {
            border-radius: 16px;
            padding: 14px 16px;
            margin-bottom: 16px;
            border: 1px solid transparent;
            background: #fff;
            box-shadow: 0 10px 22px rgba(15, 23, 42, 0.05);
        }
        .alert.success { border-color: var(--success-soft); background: var(--success-soft); color: var(--success); }
        .alert.error { border-color: var(--danger-soft); background: var(--danger-soft); color: var(--danger); }
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        .form-row { display: grid; gap: 8px; }
        .form-row label { font-size: 13px; color: var(--muted); }
        .muted { color: var(--muted); line-height: 1.6; }
        .table-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        @media (max-width: 1100px) {
            .shell { grid-template-columns: 1fr; }
            .sidebar {
                position: static;
                height: auto;
            }
        }
        @media (max-width: 980px) {
            .panels,
            .form-grid {
                grid-template-columns: 1fr;
            }
        }
        @media (max-width: 640px) {
            .main { padding: 18px 14px 28px; }
            .summary { grid-template-columns: 1fr 1fr; }
            .header { align-items: flex-start; }
            .topline { width: 100%; }
            .pill { width: 100%; justify-content: center; }
            .controls { flex-direction: column; }
            .search { width: 100%; }
            .btn { width: 100%; }
            th, td { padding: 12px 14px; }
        }
    </style>
</head>
<body>
    <div class="shell">
        <aside class="sidebar">
            <div class="brand">
                <div class="brand-mark">R</div>
                <div>
                    <strong>لوحة إدارة الرحلات</strong>
                    <span>التحكم والعمليات اليومية</span>
                </div>
            </div>

            <nav class="nav">
                <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">الرئيسية<small>نظرة عامة، الطلبات المباشرة، والأرباح</small></a>
                <a href="{{ route('admin.drivers.index') }}" class="{{ request()->routeIs('admin.drivers.*') ? 'active' : '' }}">السائقون<small>الموافقات، الحالة، والتقييمات</small></a>
                <a href="{{ route('admin.riders.index') }}" class="{{ request()->routeIs('admin.riders.*') ? 'active' : '' }}">الركاب<small>الحسابات، الحالة، والنشاط الأخير</small></a>
                <a href="{{ route('admin.rides.index') }}" class="{{ request()->routeIs('admin.rides.*') ? 'active' : '' }}">الرحلات<small>مراقبة مباشرة وحالات الرحلات</small></a>
                <a href="{{ route('admin.wallets.index') }}" class="{{ request()->routeIs('admin.wallets.*') ? 'active' : '' }}">المحافظ<small>إشعارات الإيداع ورصيد المستخدمين</small></a>
                <a href="{{ route('admin.wallet-payment-accounts.index') }}" class="{{ request()->routeIs('admin.wallet-payment-accounts.*') ? 'active' : '' }}">حسابات التحويل<small>الحسابات التي يحول عليها الكستمر</small></a>
                <a href="{{ route('admin.commission.edit') }}" class="{{ request()->routeIs('admin.commission.*') ? 'active' : '' }}">العمولة<small>إعداد نسبة المنصة</small></a>
                <a href="{{ route('admin.complaints.index') }}" class="{{ request()->routeIs('admin.complaints.*') ? 'active' : '' }}">الشكاوى<small>بلاغات الدعم والمتابعة</small></a>
                <a href="{{ route('admin.offers.index') }}" class="{{ request()->routeIs('admin.offers.*') ? 'active' : '' }}">العروض<small>أكواد الخصم والحملات</small></a>
                <a href="{{ route('admin.analytics.index') }}" class="{{ request()->routeIs('admin.analytics.*') ? 'active' : '' }}">الإحصائيات<small>الإيرادات والاتجاهات الشهرية</small></a>
            </nav>

            @auth
                <div class="userbox">
                    <div class="userline">
                        <strong>{{ auth()->user()->name }}</strong>
                        <span>{{ auth()->user()->email }}</span>
                    </div>
                    <form method="post" action="{{ route('auth.logout') }}">
                        @csrf
                        <button class="btn" type="submit" style="width:100%;">تسجيل الخروج</button>
                    </form>
                </div>
            @endauth
        </aside>
        <main class="main">
            <div class="wrap">
                @if (session('status'))
                    <div class="alert success">{{ session('status') }}</div>
                @endif
                @if ($errors->any())
                    <div class="alert error">
                        {{ $errors->first() }}
                    </div>
                @endif
                @yield('content')
            </div>
        </main>
    </div>
</body>
</html>
