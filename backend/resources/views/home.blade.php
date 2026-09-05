<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>الحساب</title>
    <style>
        :root {
            --bg: #f5f2ea;
            --panel: #ffffff;
            --line: #e7dfcf;
            --text: #111214;
            --muted: #747880;
            --primary: #e9b934;
            --primary-soft: #fff3cf;
            --accent: #30343a;
            --shadow: 0 18px 46px rgba(103, 99, 91, 0.12);
        }
        * { box-sizing: border-box; }
        html { color-scheme: light; }
        body {
            margin: 0;
            min-height: 100vh;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                radial-gradient(circle at top right, rgba(233, 185, 52, 0.14), transparent 34%),
                linear-gradient(180deg, #faf7f1 0%, var(--bg) 100%);
            color: var(--text);
            direction: rtl;
            text-align: right;
        }
        .wrap {
            max-width: 1100px;
            margin: 0 auto;
            padding: 34px 20px 40px;
        }
        .top {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
            align-items: center;
            margin-bottom: 22px;
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .mark {
            width: 48px;
            height: 48px;
            border-radius: 16px;
            display: grid;
            place-items: center;
            color: #171717;
            font-weight: 800;
            background: linear-gradient(135deg, #f6d16f 0%, var(--primary) 100%);
            box-shadow: 0 12px 30px rgba(233, 185, 52, 0.24);
        }
        .muted { color: var(--muted); line-height: 1.7; }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 12px 16px;
            border-radius: 14px;
            border: 1px solid var(--line);
            text-decoration: none;
            color: var(--text);
            background: #fff;
            cursor: pointer;
            font: inherit;
            font-weight: 700;
            transition: 140ms ease;
        }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 10px 22px rgba(103, 99, 91, 0.1); }
        .btn.primary {
            background: var(--primary);
            color: #211a00;
            border-color: var(--primary);
            box-shadow: 0 12px 26px rgba(233, 185, 52, 0.24);
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin: 20px 0;
        }
        .card,
        .panel {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 18px;
            box-shadow: var(--shadow);
        }
        .card {
            padding: 22px;
        }
        .card h2 {
            margin: 0 0 8px;
            font-size: 22px;
        }
        .actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 18px;
        }
        .pill {
            display: inline-flex;
            align-items: center;
            padding: 8px 12px;
            border-radius: 999px;
            background: var(--primary-soft);
            color: var(--primary);
            font-size: 12px;
            font-weight: 800;
        }
        .panel {
            padding: 20px;
        }
        .panel h3 {
            margin: 0 0 8px;
            font-size: 18px;
        }
        .list {
            display: grid;
            gap: 12px;
            margin-top: 14px;
        }
        .item {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            padding: 14px 16px;
            border: 1px solid var(--line);
            border-radius: 16px;
            background: #fffdf8;
        }
        .item strong { display: block; margin-bottom: 4px; }
        .item span { color: var(--muted); font-size: 13px; }
        @media (max-width: 920px) {
            .grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 640px) {
            .grid { grid-template-columns: 1fr; }
            .wrap { padding: 18px 14px 24px; }
        }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="top">
            <div class="brand">
                <div class="mark">R</div>
                <div>
                    <h1 style="margin:0;">أهلًا {{ auth()->user()->name }}</h1>
                    <div class="muted">{{ auth()->user()->email }}</div>
                </div>
            </div>
            <form method="post" action="{{ route('auth.logout') }}">
                @csrf
                <button class="btn" type="submit">تسجيل الخروج</button>
            </form>
        </div>

        <div class="card">
            <div class="pill">الحساب نشط</div>
            <h2>حسابك جاهز للاستخدام</h2>
            <p class="muted">هذا المساحة مخصصة للحسابات العادية داخل النظام. إذا كان حسابك إداريًا، فستظهر لك لوحة الإدارة كاملة من نفس الدخول.</p>

            @if (auth()->user()->isAdmin())
                <div class="actions">
                    <a class="btn primary" href="{{ route('admin.dashboard') }}">الدخول إلى لوحة الإدارة</a>
                </div>
            @endif
        </div>

        <div class="grid">
            <div class="panel">
                <h3>الوصول السريع</h3>
                <div class="muted">واجهة مبسطة للحسابات العادية مع مظهر أوضح وأقل ازدحامًا.</div>
            </div>
            <div class="panel">
                <h3>مناسب للجوال</h3>
                <div class="muted">توزيع البطاقات صار مرنًا حتى يظل الشكل نظيفًا على الشاشات الصغيرة.</div>
            </div>
            <div class="panel">
                <h3>لغة عربية واضحة</h3>
                <div class="muted">العناوين والنصوص كلها الآن أكثر اتساقًا مع اتجاه القراءة العربي.</div>
            </div>
            <div class="panel">
                <h3>جاهز للتوسعة</h3>
                <div class="muted">تستطيع لاحقًا إضافة تفاصيل الرحلات أو التنبيهات داخل هذه الصفحة بسهولة.</div>
            </div>
        </div>
    </div>
</body>
</html>
