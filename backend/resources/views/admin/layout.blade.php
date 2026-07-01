<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'لوحة الإدارة' }}</title>
    <style>
        :root {
            --bg: #f5f7fb;
            --panel: #ffffff;
            --line: #d8e2ef;
            --text: #102033;
            --muted: #5f7186;
            --primary: #0f766e;
            --primary-soft: #dff5f1;
            --warn: #c2410c;
            --warn-soft: #fff1e8;
            --good: #166534;
            --good-soft: #e8f8ee;
            --blue: #1d4ed8;
            --blue-soft: #e8efff;
            --danger: #b91c1c;
            --danger-soft: #fde8e8;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: var(--bg);
            color: var(--text);
            direction: rtl;
            text-align: right;
        }
        a { color: inherit; }
        .shell {
            display: grid;
            grid-template-columns: 260px minmax(0, 1fr);
            min-height: 100vh;
        }
        .sidebar {
            background: #0f172a;
            color: #e2e8f0;
            padding: 22px 18px;
            position: sticky;
            top: 0;
            height: 100vh;
            overflow: auto;
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 24px;
        }
        .brand-mark {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            background: var(--primary);
            display: grid;
            place-items: center;
            color: #fff;
            font-weight: 700;
        }
        .brand strong { display: block; }
        .brand span { color: #94a3b8; font-size: 13px; }
        .nav {
            display: grid;
            gap: 8px;
            margin-top: 18px;
        }
        .nav a {
            text-decoration: none;
            padding: 12px 14px;
            border-radius: 12px;
            color: #cbd5e1;
            background: transparent;
            border: 1px solid transparent;
            display: block;
        }
        .nav a.active {
            color: #fff;
            background: rgba(15, 118, 110, 0.18);
            border-color: rgba(15, 118, 110, 0.35);
        }
        .nav small {
            display: block;
            margin-top: 4px;
            color: #94a3b8;
        }
        .userbox {
            margin-top: 22px;
            padding-top: 16px;
            border-top: 1px solid rgba(148, 163, 184, 0.2);
            display: grid;
            gap: 12px;
        }
        .userline {
            display: grid;
            gap: 4px;
        }
        .userline strong { color: #fff; }
        .userline span { color: #94a3b8; font-size: 13px; }
        .main {
            padding: 28px 20px 40px;
            min-width: 0;
        }
        .wrap { max-width: 1400px; margin: 0 auto; }
        .header {
            display: flex;
            gap: 16px;
            justify-content: space-between;
            align-items: end;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        h1 { margin: 0; font-size: 30px; letter-spacing: 0; }
        .subtitle { margin: 8px 0 0; color: var(--muted); }
        .topline { display: flex; gap: 12px; flex-wrap: wrap; }
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 12px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: var(--panel);
            color: var(--muted);
            text-decoration: none;
            font-size: 14px;
        }
        .pill.active {
            border-color: transparent;
            background: var(--primary);
            color: #fff;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
            gap: 14px;
            margin: 18px 0 18px;
        }
        .metric {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 18px;
        }
        .metric .label { color: var(--muted); font-size: 13px; margin-bottom: 8px; }
        .metric .value { font-size: 28px; font-weight: 700; line-height: 1.1; }
        .metric .hint { margin-top: 8px; color: var(--muted); font-size: 13px; }
        .panels {
            display: grid;
            grid-template-columns: 1.6fr 1fr;
            gap: 16px;
            align-items: start;
        }
        .panel {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 16px;
            overflow: hidden;
        }
        .panel-header {
            padding: 16px 18px 0;
        }
        .panel-title {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }
        .panel-title h2 { margin: 0; font-size: 18px; }
        .panel-title p { margin: 6px 0 0; color: var(--muted); font-size: 14px; }
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
            border-radius: 12px;
            padding: 10px 12px;
            background: #fff;
        }
        .search input, .input, .select, .textarea {
            border: 1px solid var(--line);
            outline: 0;
            width: 100%;
            font: inherit;
            background: #fff;
            border-radius: 12px;
            padding: 10px 12px;
        }
        .search input { border: 0; padding: 0; }
        .btn {
            border: 1px solid var(--line);
            background: #fff;
            color: var(--text);
            border-radius: 12px;
            padding: 10px 14px;
            font: inherit;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }
        .btn.primary { background: var(--primary); color: #fff; border-color: var(--primary); }
        .btn.blue { background: var(--blue); color: #fff; border-color: var(--blue); }
        .btn.danger { background: var(--danger); color: #fff; border-color: var(--danger); }
        .btn.ghost { background: transparent; }
        table { width: 100%; border-collapse: collapse; }
        th, td {
            padding: 14px 18px;
            text-align: left;
            border-top: 1px solid var(--line);
            vertical-align: top;
            font-size: 14px;
        }
        th { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .04em; }
        .status {
            display: inline-flex;
            align-items: center;
            padding: 6px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
        }
        .status.requested, .status.accepted, .status.arrived, .status.in_progress, .status.pending {
            background: var(--warn-soft);
            color: var(--warn);
        }
        .status.completed, .status.approved, .status.active, .status.resolved {
            background: var(--good-soft);
            color: var(--good);
        }
        .status.rejected, .status.suspended, .status.closed, .status.inactive, .status.open {
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
            font-weight: 700;
        }
        .list { padding: 10px 18px 18px; }
        .list-item {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            padding: 14px 0;
            border-top: 1px solid var(--line);
        }
        .list-item:first-child { border-top: 0; }
        .list-item strong { display: block; margin-bottom: 5px; }
        .list-item small { color: var(--muted); }
        .stack { display: grid; gap: 12px; margin-top: 16px; }
        .mini {
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 14px;
            background: #fff;
        }
        .mini .label { font-size: 13px; color: var(--muted); }
        .mini .value { font-size: 22px; font-weight: 700; margin-top: 6px; }
        .mini .note { margin-top: 6px; color: var(--muted); font-size: 13px; }
        .empty {
            padding: 24px 18px;
            color: var(--muted);
            border-top: 1px solid var(--line);
        }
        .alert {
            border-radius: 14px;
            padding: 14px 16px;
            margin-bottom: 16px;
            border: 1px solid transparent;
            background: #fff;
        }
        .alert.success { border-color: var(--good-soft); background: var(--good-soft); color: var(--good); }
        .alert.error { border-color: var(--danger-soft); background: var(--danger-soft); color: var(--danger); }
        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        .form-row { display: grid; gap: 8px; }
        .form-row label { font-size: 13px; color: var(--muted); }
        .muted { color: var(--muted); }
        .table-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        @media (max-width: 1100px) {
            .shell { grid-template-columns: 1fr; }
            .sidebar { position: static; height: auto; }
        }
        @media (max-width: 980px) {
            .panels, .form-grid { grid-template-columns: 1fr; }
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
                <span>لوحة العمليات</span>
            </div>
        </div>

            <nav class="nav">
                <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">الرئيسية<small>نظرة عامة، الطلبات المباشرة، والأرباح</small></a>
                <a href="{{ route('admin.drivers.index') }}" class="{{ request()->routeIs('admin.drivers.*') ? 'active' : '' }}">السائقون<small>الموافقات، الحالة، والتقييمات</small></a>
                <a href="{{ route('admin.riders.index') }}" class="{{ request()->routeIs('admin.riders.*') ? 'active' : '' }}">الركاب<small>الحسابات، الحالة، والنشاط الأخير</small></a>
                <a href="{{ route('admin.rides.index') }}" class="{{ request()->routeIs('admin.rides.*') ? 'active' : '' }}">الرحلات<small>مراقبة مباشرة وحالات الرحلة</small></a>
                <a href="{{ route('admin.commission.edit') }}" class="{{ request()->routeIs('admin.commission.*') ? 'active' : '' }}">العمولة<small>إعدادات نسبة المنصة</small></a>
                <a href="{{ route('admin.complaints.index') }}" class="{{ request()->routeIs('admin.complaints.*') ? 'active' : '' }}">الشكاوى<small>بلاغات الدعم وحلّها</small></a>
                <a href="{{ route('admin.offers.index') }}" class="{{ request()->routeIs('admin.offers.*') ? 'active' : '' }}">العروض<small>أكواد الخصم والحملات</small></a>
                <a href="{{ route('admin.analytics.index') }}" class="{{ request()->routeIs('admin.analytics.*') ? 'active' : '' }}">الإحصائيات<small>الإيرادات والأداء</small></a>
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
