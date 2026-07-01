<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>الحساب</title>
    <style>
        body {
            margin: 0;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #f5f7fb;
            color: #102033;
            direction: rtl;
            text-align: right;
        }
        .wrap {
            max-width: 900px;
            margin: 0 auto;
            padding: 32px 20px;
        }
        .card {
            background: #fff;
            border: 1px solid #d8e2ef;
            border-radius: 16px;
            padding: 24px;
        }
        .muted { color: #5f7186; }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 12px 16px;
            border-radius: 12px;
            border: 1px solid #d8e2ef;
            text-decoration: none;
            color: #102033;
            background: #fff;
            cursor: pointer;
        }
        .top { display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="top" style="margin-bottom:16px;">
            <div>
                <h1>أهلًا {{ auth()->user()->name }}</h1>
                <div class="muted">{{ auth()->user()->email }}</div>
            </div>
            <form method="post" action="{{ route('auth.logout') }}">
                @csrf
                <button class="btn" type="submit">تسجيل الخروج</button>
            </form>
        </div>

        <div class="card">
            <h2>حسابك جاهز</h2>
            <p class="muted">يمكنك الآن استخدام النظام بحساب البريد الإلكتروني وكلمة المرور. إذا كنت أدمن، ستجد لوحة الإدارة متاحة من نفس الحساب.</p>
            @if (auth()->user()->isAdmin())
                <p><a class="btn" href="{{ route('admin.dashboard') }}">الدخول إلى لوحة الإدارة</a></p>
            @endif
        </div>
    </div>
</body>
</html>
