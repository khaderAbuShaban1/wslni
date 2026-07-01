<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تسجيل الدخول</title>
    <style>
        :root {
            --bg: #eef3f8;
            --panel: #ffffff;
            --line: #d9e2ec;
            --text: #0f172a;
            --muted: #64748b;
            --primary: #0f766e;
            --primary-soft: #dff5f1;
            --shadow: 0 20px 60px rgba(15, 23, 42, 0.10);
            --danger: #b91c1c;
            --danger-soft: #fde8e8;
        }
        * { box-sizing: border-box; }
        html { color-scheme: light; }
        body {
            margin: 0;
            min-height: 100vh;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                radial-gradient(circle at top right, rgba(15, 118, 110, 0.08), transparent 36%),
                radial-gradient(circle at bottom left, rgba(29, 78, 216, 0.06), transparent 32%),
                var(--bg);
            color: var(--text);
            direction: rtl;
        }
        .screen {
            min-height: 100vh;
            display: grid;
            grid-template-columns: minmax(280px, 1fr) minmax(420px, 560px);
        }
        .hero {
            padding: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .hero-inner {
            width: min(540px, 100%);
            color: var(--text);
        }
        .brand {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 22px;
        }
        .mark {
            width: 50px;
            height: 50px;
            border-radius: 16px;
            background: linear-gradient(135deg, var(--primary) 0%, #10b981 100%);
            display: grid;
            place-items: center;
            color: #fff;
            font-weight: 800;
            box-shadow: 0 16px 30px rgba(15, 118, 110, 0.28);
        }
        .brand strong {
            display: block;
            font-size: 16px;
        }
        .brand span {
            display: block;
            margin-top: 3px;
            color: var(--muted);
            font-size: 13px;
        }
        h1 {
            margin: 0;
            font-size: clamp(34px, 4vw, 54px);
            line-height: 1.08;
            letter-spacing: 0;
        }
        .lead {
            margin: 16px 0 0;
            color: var(--muted);
            font-size: 18px;
            line-height: 1.9;
            max-width: 640px;
        }
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px;
            margin-top: 28px;
        }
        .feature {
            background: rgba(255, 255, 255, 0.75);
            border: 1px solid rgba(217, 226, 236, 0.9);
            border-radius: 18px;
            padding: 16px;
            box-shadow: 0 12px 30px rgba(15, 23, 42, 0.04);
            backdrop-filter: blur(12px);
        }
        .feature strong {
            display: block;
            margin-bottom: 6px;
            font-size: 15px;
        }
        .feature span {
            color: var(--muted);
            font-size: 13px;
            line-height: 1.7;
        }
        .panel {
            background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%);
            border-inline-start: 1px solid var(--line);
            padding: 28px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card {
            width: min(520px, 100%);
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 22px;
            padding: 30px;
            box-shadow: var(--shadow);
        }
        .card-head {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 18px;
        }
        .card-head h2 {
            margin: 0;
            font-size: 28px;
        }
        .card-head p {
            margin: 8px 0 0;
            color: var(--muted);
            line-height: 1.7;
        }
        .alert {
            margin: 16px 0 0;
            padding: 12px 14px;
            border-radius: 14px;
            background: var(--danger-soft);
            color: var(--danger);
            border: 1px solid #f2c2c2;
        }
        .form {
            margin-top: 22px;
            display: grid;
            gap: 14px;
        }
        .field {
            display: grid;
            gap: 8px;
        }
        .field label {
            color: var(--muted);
            font-size: 13px;
        }
        input {
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 13px 14px;
            font: inherit;
            width: 100%;
            outline: 0;
            background: #fff;
            transition: 120ms ease;
        }
        input:focus {
            border-color: rgba(15, 118, 110, 0.45);
            box-shadow: 0 0 0 4px rgba(15, 118, 110, 0.12);
        }
        .remember {
            display: flex;
            align-items: center;
            gap: 10px;
            color: var(--muted);
            font-size: 13px;
        }
        .remember input {
            width: 18px;
            height: 18px;
            margin: 0;
            accent-color: var(--primary);
            box-shadow: none;
        }
        .btn {
            border: 1px solid transparent;
            border-radius: 14px;
            padding: 13px 16px;
            font: inherit;
            font-weight: 800;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            text-decoration: none;
            transition: 140ms ease;
        }
        .btn:hover { transform: translateY(-1px); }
        .primary-btn {
            background: linear-gradient(135deg, var(--primary) 0%, #0e9f8a 100%);
            color: #fff;
            box-shadow: 0 14px 30px rgba(15, 118, 110, 0.25);
        }
        .footer {
            margin-top: 18px;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.7;
        }
        @media (max-width: 980px) {
            .screen {
                grid-template-columns: 1fr;
            }
            .hero {
                padding: 24px 18px 0;
            }
            .panel {
                border-inline-start: 0;
                border-top: 1px solid var(--line);
                padding: 18px;
            }
        }
        @media (max-width: 560px) {
            .feature-grid {
                grid-template-columns: 1fr;
            }
            .card {
                padding: 22px;
                border-radius: 18px;
            }
            h1 {
                font-size: 30px;
            }
        }
    </style>
</head>
<body>
    <div class="screen">
        <section class="hero">
            <div class="hero-inner">
                <div class="brand">
                    <div class="mark">R</div>
                    <div>
                        <strong>WSLNI</strong>
                        <span>لوحة إدارة توصيل الركاب</span>
                    </div>
                </div>

                <h1>تسجيل دخول أنيق وواضح لبوابة الإدارة</h1>
                <p class="lead">واجهة دخول عربية، سريعة، ومهيأة للإدارة. كل شيء هنا يفتح مباشرة على النظام بدون تشتيت، مع تصميم أوضح وأهدأ أثناء الاستخدام اليومي.</p>

                <div class="feature-grid">
                    <div class="feature">
                        <strong>إدارة مركّزة</strong>
                        <span>مراقبة السائقين والركاب والرحلات من شاشة واحدة مرتبة.</span>
                    </div>
                    <div class="feature">
                        <strong>مظهر أوضح</strong>
                        <span>تباين أفضل ومساحات تنفس تخلي القراءة أسرع وأريح.</span>
                    </div>
                    <div class="feature">
                        <strong>RTL عربي</strong>
                        <span>كل الترتيب مكتوب ومضبوط للاتجاه العربي من البداية.</span>
                    </div>
                    <div class="feature">
                        <strong>جاهز للتوسع</strong>
                        <span>التصميم الحالي يترك مساحة نظيفة لميزات جديدة لاحقًا.</span>
                    </div>
                </div>
            </div>
        </section>

        <section class="panel">
            <div class="card">
                <div class="card-head">
                    <div class="mark">R</div>
                    <div>
                        <h2>تسجيل الدخول</h2>
                        <p>أدخل البريد الإلكتروني وكلمة المرور للوصول إلى حسابك.</p>
                    </div>
                </div>

                @if ($errors->any())
                    <div class="alert">{{ $errors->first() }}</div>
                @endif

                <form class="form" method="post" action="{{ route('auth.login.store') }}">
                    @csrf
                    <label class="field">
                        <span>البريد الإلكتروني</span>
                        <input type="email" name="email" value="{{ old('email') }}" required autocomplete="email">
                    </label>

                    <label class="field">
                        <span>كلمة المرور</span>
                        <input type="password" name="password" required autocomplete="current-password">
                    </label>

                    <label class="remember">
                        <input type="checkbox" name="remember" value="1">
                        <span>تذكرني</span>
                    </label>

                    <button class="btn primary-btn" type="submit">تسجيل الدخول</button>
                </form>

                <div class="footer">يمكنك استخدام حسابك للدخول إلى النظام. إذا كان الحساب إداريًا، ستنتقل مباشرة إلى لوحة الإدارة بعد تسجيل الدخول.</div>
            </div>
        </section>
    </div>
</body>
</html>
