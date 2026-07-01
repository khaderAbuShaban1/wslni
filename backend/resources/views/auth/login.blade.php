<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تسجيل الدخول</title>
    <style>
        :root {
            --panel: #ffffff;
            --line: #d8e2ef;
            --text: #102033;
            --muted: #5f7186;
            --primary: #0f766e;
            --danger: #b91c1c;
            --danger-soft: #fde8e8;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: linear-gradient(180deg, #f7fafc 0%, #eef4f9 100%);
            color: var(--text);
            direction: rtl;
            text-align: right;
        }
        .card {
            width: min(480px, calc(100vw - 32px));
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 18px;
            padding: 28px;
            box-shadow: 0 18px 48px rgba(16, 32, 51, 0.08);
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 18px;
        }
        .mark {
            width: 44px;
            height: 44px;
            border-radius: 14px;
            background: var(--primary);
            color: #fff;
            display: grid;
            place-items: center;
            font-weight: 700;
        }
        h1 { margin: 0 0 8px; font-size: 28px; }
        p { margin: 0; color: var(--muted); line-height: 1.7; }
        .alert {
            margin: 16px 0 0;
            padding: 12px 14px;
            border-radius: 12px;
            background: var(--danger-soft);
            color: var(--danger);
            border: 1px solid #f2c2c2;
        }
        .actions { margin-top: 22px; display: grid; gap: 12px; }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            text-decoration: none;
            border-radius: 12px;
            padding: 13px 16px;
            font-weight: 700;
            border: 1px solid transparent;
            cursor: pointer;
        }
        .primary-btn {
            background: var(--primary);
            color: #fff;
        }
        .hint { font-size: 13px; color: var(--muted); line-height: 1.6; margin-top: 16px; }
        .footer { margin-top: 18px; font-size: 13px; color: var(--muted); }
    </style>
</head>
<body>
    <main class="card">
        <div class="brand">
            <div class="mark">R</div>
            <div>
                <h1>تسجيل الدخول</h1>
                <p>أدخل البريد الإلكتروني وكلمة المرور للوصول إلى حسابك.</p>
            </div>
        </div>

        @if ($errors->any())
            <div class="alert">{{ $errors->first() }}</div>
        @endif

        <form class="actions" method="post" action="{{ route('auth.login.store') }}">
            @csrf
            <div style="display:grid; gap:12px;">
                <label>
                    <div class="hint" style="margin-top:0;margin-bottom:6px;">البريد الإلكتروني</div>
                    <input type="email" name="email" value="{{ old('email') }}" required style="width:100%;border:1px solid var(--line);border-radius:12px;padding:13px 14px;">
                </label>
                <label>
                    <div class="hint" style="margin-top:0;margin-bottom:6px;">كلمة المرور</div>
                    <input type="password" name="password" required style="width:100%;border:1px solid var(--line);border-radius:12px;padding:13px 14px;">
                </label>
                <label style="display:flex;align-items:center;gap:8px;">
                    <input type="checkbox" name="remember" value="1">
                    <span class="hint" style="margin-top:0;">تذكرني</span>
                </label>
                <button class="btn primary-btn" type="submit">تسجيل الدخول</button>
            </div>
        </form>

        <div class="footer">يمكنك استخدام حسابك للدخول إلى النظام.</div>
    </main>
</body>
</html>
