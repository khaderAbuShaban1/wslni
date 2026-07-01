@extends('admin.layout', ['title' => 'الركاب'])

@section('content')
    <div class="header">
        <div>
            <h1>الركاب</h1>
            <p class="subtitle">راجع حسابات العملاء وأوقف أو فعّل الحساب عند الحاجة.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'الكل', 'active' => 'نشط', 'suspended' => 'موقوف'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.riders.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">نشط</div><div class="value">{{ $activeCount }}</div><div class="hint">جاهز للحجز</div></div>
        <div class="metric"><div class="label">موقوف</div><div class="value">{{ $suspendedCount }}</div><div class="hint">موقوف مؤقتًا</div></div>
        <div class="metric"><div class="label">إجمالي الركاب</div><div class="value">{{ $riders->count() }}</div><div class="hint">في العرض الحالي</div></div>
        <div class="metric"><div class="label">الفلتر</div><div class="value">{{ strtoupper($status) }}</div><div class="hint">النطاق الحالي</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.riders.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>بحث</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="ابحث بالاسم أو البريد الإلكتروني">
                </label>
                <button class="btn primary" type="submit">تصفية</button>
                <a class="btn" href="{{ route('admin.riders.index') }}">إعادة ضبط</a>
            </form>
        </div>

        @if ($riders->isEmpty())
            <div class="empty">لا يوجد ركاب.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>الراكب</th>
                        <th>بيانات التواصل</th>
                        <th>الحالة</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($riders as $rider)
                        <tr>
                            <td>
                                <strong>{{ $rider->name }}</strong>
                                <div class="muted">سُجّل في {{ $rider->created_at->format('M d, Y') }}</div>
                            </td>
                            <td>
                                <div>{{ $rider->email }}</div>
                                <div class="muted">{{ $rider->phone ?? 'لا يوجد رقم' }}</div>
                            </td>
                            <td><span class="status {{ $rider->account_status }}">{{ $rider->account_status === 'active' ? 'نشط' : 'موقوف' }}</span></td>
                            <td>
                                <div class="table-actions">
                                    <form method="post" action="{{ route('admin.riders.activate', $rider) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn blue" type="submit">تفعيل</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.riders.suspend', $rider) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn danger" type="submit">إيقاف</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </div>
@endsection
