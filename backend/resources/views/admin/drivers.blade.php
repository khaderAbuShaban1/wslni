@extends('admin.layout', ['title' => 'السائقون'])

@section('content')
    <div class="header">
        <div>
            <h1>السائقون</h1>
            <p class="subtitle">وافق على السائقين الجدد وراجع حالتهم وتواجدهم.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'الكل', 'pending' => 'قيد الانتظار', 'approved' => 'معتمد', 'rejected' => 'مرفوض'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.drivers.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">قيد الانتظار</div><div class="value">{{ $pendingCount }}</div><div class="hint">بانتظار الموافقة</div></div>
        <div class="metric"><div class="label">معتمدون</div><div class="value">{{ $approvedCount }}</div><div class="hint">جاهزون لاستقبال الرحلات</div></div>
        <div class="metric"><div class="label">مرفوضون</div><div class="value">{{ $rejectedCount }}</div><div class="hint">بحاجة إلى مراجعة</div></div>
        <div class="metric"><div class="label">متصلون</div><div class="value">{{ $onlineCount }}</div><div class="hint">جاهزون الآن</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.drivers.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>بحث</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="ابحث بالاسم أو الرخصة أو رقم اللوحة">
                </label>
                <button class="btn primary" type="submit">تصفية</button>
                <a class="btn" href="{{ route('admin.drivers.index') }}">إعادة ضبط</a>
            </form>
        </div>

        @if ($drivers->isEmpty())
            <div class="empty">لا يوجد سائقون.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>السائق</th>
                        <th>المركبة</th>
                        <th>الموافقة</th>
                        <th>الاتصال</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($drivers as $driver)
                        <tr>
                            <td>
                                <strong>{{ $driver->user?->name }}</strong>
                                <div class="muted">{{ $driver->user?->email }} · {{ $driver->user?->phone ?? 'لا يوجد رقم' }}</div>
                            </td>
                            <td>
                                <strong>{{ $driver->vehicle_type ?? 'مركبة غير معروفة' }}</strong>
                                <div class="muted">{{ $driver->vehicle_plate ?? 'لا توجد لوحة' }} · التقييم {{ $driver->rating }}</div>
                            </td>
                            <td><span class="status {{ $driver->approval_status }}">{{ $driver->approval_status === 'approved' ? 'معتمد' : ($driver->approval_status === 'pending' ? 'قيد الانتظار' : 'مرفوض') }}</span></td>
                            <td><span class="status {{ $driver->is_online ? 'approved' : 'inactive' }}">{{ $driver->is_online ? 'متصل' : 'غير متصل' }}</span></td>
                            <td>
                                <div class="table-actions">
                                    <form method="post" action="{{ route('admin.drivers.approve', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn blue" type="submit">موافقة</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.drivers.reject', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn danger" type="submit">رفض</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.drivers.toggle-online', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn" type="submit">تبديل الاتصال</button>
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
