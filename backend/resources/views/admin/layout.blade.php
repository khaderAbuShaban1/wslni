<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'لوحة الإدارة' }}</title>
    <style>
        :root {
            --bg: #f5f2ea;
            --panel: #ffffff;
            --panel-soft: #fcfaf4;
            --line: #e7dfcf;
            --line-strong: #d9cfba;
            --text: #111214;
            --muted: #747880;
            --primary: #e9b934;
            --primary-soft: #fff3cf;
            --accent: #30343a;
            --accent-soft: #eceef1;
            --warning: #d99c18;
            --warning-soft: #fff3d8;
            --danger: #c73a31;
            --danger-soft: #fde7e3;
            --success: #20835b;
            --success-soft: #e8f8ee;
            --shadow: 0 18px 48px rgba(103, 99, 91, 0.12);
        }
        * { box-sizing: border-box; }
        html { color-scheme: light; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                linear-gradient(180deg, rgba(233, 185, 52, 0.12) 0%, rgba(233, 185, 52, 0.02) 220px, transparent 220px),
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
            background: linear-gradient(180deg, #111214 0%, #1a1c21 100%);
            color: #f5f5f6;
            border-left: 1px solid rgba(243, 196, 85, 0.1);
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 8px 18px;
            margin-bottom: 8px;
            border-bottom: 1px solid rgba(243, 196, 85, 0.16);
        }
        .brand-mark {
            width: 44px;
            height: 44px;
            border-radius: 14px;
            background: linear-gradient(135deg, #f6d16f 0%, var(--primary) 100%);
            display: grid;
            place-items: center;
            color: #171717;
            font-weight: 800;
            box-shadow: 0 12px 30px rgba(233, 185, 52, 0.32);
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
            color: #a9b8cc;
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
            color: #d7d9dd;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid transparent;
            transition: 160ms ease;
        }
        .nav a:hover {
            background: rgba(243, 196, 85, 0.08);
            border-color: rgba(243, 196, 85, 0.16);
            transform: translateY(-1px);
        }
        .nav a.active {
            color: #fff4cf;
            background: rgba(243, 196, 85, 0.14);
            border-color: rgba(243, 196, 85, 0.34);
            box-shadow: inset 0 0 0 1px rgba(255, 244, 207, 0.04);
        }
        .nav small {
            display: block;
            margin-top: 4px;
            color: #aeb8c8;
            line-height: 1.5;
        }
        .userbox {
            margin-top: 22px;
            padding: 16px 0 0;
            border-top: 1px solid rgba(243, 196, 85, 0.14);
            display: grid;
            gap: 12px;
        }
        .userline strong { color: #fff; }
        .userline span {
            display: block;
            margin-top: 4px;
            color: #aeb8c8;
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
            color: #211a00;
            box-shadow: 0 10px 24px rgba(233, 185, 52, 0.28);
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 14px;
            margin: 18px 0 18px;
        }
        .metric {
            background: linear-gradient(180deg, #fffdf8 0%, #ffffff 100%);
            border: 1px solid var(--line);
            border-radius: 16px;
            padding: 18px;
            box-shadow: 0 8px 24px rgba(103, 99, 91, 0.08);
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
        .realtime-indicator {
            position: fixed;
            left: 22px;
            bottom: 22px;
            z-index: 1000;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            max-width: min(360px, calc(100vw - 44px));
            padding: 10px 14px;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: rgba(255, 255, 255, .96);
            box-shadow: 0 12px 28px rgba(15, 23, 42, .12);
            color: var(--muted);
            font-size: 13px;
            transition: opacity 180ms ease, transform 180ms ease;
        }
        .realtime-indicator::before {
            content: '';
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--success);
            box-shadow: 0 0 0 4px var(--success-soft);
        }
        .realtime-indicator.updating::before {
            background: var(--primary);
            box-shadow: 0 0 0 4px var(--primary-soft);
        }
        .realtime-indicator.offline::before {
            background: var(--danger);
            box-shadow: 0 0 0 4px var(--danger-soft);
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
    <div id="realtime-indicator" class="realtime-indicator" role="status" aria-live="polite">
        التحديث المباشر قيد الاتصال…
    </div>
    <script type="module">
        import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.2.1/firebase-app.js';
        import { getAuth, signInWithCustomToken } from 'https://www.gstatic.com/firebasejs/12.2.1/firebase-auth.js';
        import { getDatabase, onValue, ref } from 'https://www.gstatic.com/firebasejs/12.2.1/firebase-database.js';

        const app = initializeApp({
            apiKey: 'AIzaSyCRs-Z8vvQOkhpMP81XmUAXTrgSHRpx76o',
            authDomain: 'wslni-527a2.firebaseapp.com',
            databaseURL: 'https://wslni-527a2-default-rtdb.europe-west1.firebasedatabase.app',
            projectId: 'wslni-527a2',
        });

        const indicator = document.getElementById('realtime-indicator');
        let initialized = false;
        let refreshing = false;
        let refreshTimer;

        const setRealtimeStatus = (message, state = '') => {
            indicator.textContent = message;
            indicator.className = `realtime-indicator ${state}`.trim();
        };

        const isEditing = () => {
            const active = document.activeElement;
            return active instanceof HTMLInputElement ||
                active instanceof HTMLTextAreaElement ||
                active instanceof HTMLSelectElement;
        };

        const refreshPageContent = async () => {
            if (refreshing) return;
            if (isEditing()) {
                setRealtimeStatus('وصل تحديث جديد — سيظهر بعد الانتهاء من الكتابة.', 'updating');
                window.clearTimeout(refreshTimer);
                refreshTimer = window.setTimeout(refreshPageContent, 2500);
                return;
            }

            refreshing = true;
            setRealtimeStatus('جارٍ تحديث البيانات مباشرة…', 'updating');
            try {
                const response = await fetch(window.location.href, {
                    credentials: 'same-origin',
                    cache: 'no-store',
                    headers: {
                        Accept: 'text/html',
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                });
                if (!response.ok) throw new Error('Unable to refresh admin data.');

                const documentFragment = new DOMParser().parseFromString(await response.text(), 'text/html');
                const currentWrap = document.querySelector('.main .wrap');
                const nextWrap = documentFragment.querySelector('.main .wrap');
                if (!currentWrap || !nextWrap) throw new Error('Admin content was not found.');

                // Replace only the server-rendered data region. Navigation,
                // scroll position, and the Firebase connection stay intact.
                currentWrap.replaceChildren(...Array.from(nextWrap.childNodes).map((node) => node.cloneNode(true)));
                setRealtimeStatus('تم تحديث البيانات مباشرة.');
            } catch (_) {
                setRealtimeStatus('تعذر تحديث البيانات مباشرة.', 'offline');
            } finally {
                refreshing = false;
            }
        };

        const scheduleRefresh = () => {
            window.clearTimeout(refreshTimer);
            refreshTimer = window.setTimeout(refreshPageContent, 150);
        };

        fetch('{{ route('admin.firebase.token') }}', { headers: { Accept: 'application/json' } })
            .then((response) => response.ok ? response.json() : Promise.reject(response))
            .then(({ token }) => token && signInWithCustomToken(getAuth(app), token))
            .then(() => onValue(ref(getDatabase(app), 'admin/events'), () => {
                // The first callback is Firebase's initial snapshot, not a new update.
                if (!initialized) {
                    initialized = true;
                    setRealtimeStatus('التحديث المباشر متصل.');
                    return;
                }
                scheduleRefresh();
            }, () => setRealtimeStatus('انقطع التحديث المباشر.', 'offline')))
            .catch(() => setRealtimeStatus('التحديث المباشر غير متاح.', 'offline'));
    </script>
</body>
</html>
