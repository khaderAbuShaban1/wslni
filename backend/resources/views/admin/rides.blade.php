@extends('admin.layout', ['title' => 'الرحلات'])

@section('content')
    <div class="header">
        <div>
            <h1>الرحلات</h1>
            <p class="subtitle">راقب الرحلات النشطة، وراجع الرحلات المكتملة، وحدّث الحالة مباشرة.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'الكل', 'pending' => 'معلقة', 'receiving_offers' => 'تستقبل عروض', 'driver_selected' => 'تم اختيار سائق', 'driver_confirmed' => 'مؤكدة', 'driver_on_the_way' => 'السائق في الطريق', 'driver_arrived' => 'وصل السائق', 'trip_started' => 'قيد التنفيذ', 'trip_completed' => 'مكتملة', 'rated' => 'مقيّمة'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.rides.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">مطلوبة</div><div class="value">{{ $requestedCount }}</div><div class="hint">بانتظار التوزيع</div></div>
        <div class="metric"><div class="label">قيد التنفيذ</div><div class="value">{{ $inProgressCount }}</div><div class="hint">تتحرك الآن</div></div>
        <div class="metric"><div class="label">مكتملة</div><div class="value">{{ $completedCount }}</div><div class="hint">أغلقت بنجاح</div></div>
        <div class="metric"><div class="label">الفلتر الحالي</div><div class="value">{{ strtoupper($status) }}</div><div class="hint">نطاق القائمة</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.rides.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>بحث</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="ابحث عن عنوان أو اسم راكب">
                </label>
                <button class="btn primary" type="submit">تصفية</button>
                <a class="btn" href="{{ route('admin.rides.index') }}">إعادة ضبط</a>
            </form>
        </div>

        @if ($rides->isEmpty())
            <div class="empty">لا توجد رحلات.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>الراكب</th>
                        <th>المسار</th>
                        <th>الحالة</th>
                        <th>الأرقام</th>
                        <th>تحديث سريع</th>
                    </tr>
                </thead>
                <tbody>
                    @php
                        $statusLabels = [
                            'pending' => 'معلقة',
                            'receiving_offers' => 'تستقبل عروض',
                            'driver_selected' => 'تم اختيار سائق',
                            'driver_confirmed' => 'مؤكدة',
                            'driver_on_the_way' => 'السائق في الطريق',
                            'driver_arrived' => 'وصل السائق',
                            'trip_started' => 'قيد التنفيذ',
                            'trip_completed' => 'مكتملة',
                            'rated' => 'مقيّمة',
                            'cancelled' => 'ملغاة',
                        ];
                    @endphp
                    @foreach ($rides as $ride)
                        <tr>
                            <td>
                                <strong>{{ $ride->customer?->name ?? 'غير معروف' }}</strong>
                                <div class="muted">{{ $ride->driver?->name ?? 'غير مسندة' }}</div>
                            </td>
                            <td>
                                <strong>{{ $ride->pickup_address }}</strong>
                                <div class="muted">إلى {{ $ride->dropoff_address }}</div>
                            </td>
                            <td><span class="status {{ $ride->status }}">{{ $statusLabels[$ride->status] ?? $ride->status }}</span></td>
                            <td>
                                <div>الأجرة: {{ number_format((float) ($ride->actual_fare ?? $ride->fare_estimate ?? 0), 2) }} ₪</div>
                                <div class="muted">المسافة: {{ $ride->distance_km ?? 'غير متوفر' }} كم</div>
                            </td>
                            <td>
                                <form method="post" action="{{ route('admin.rides.status', $ride) }}" class="form-grid" style="grid-template-columns: 1fr 1fr; align-items:end;">
                                    @csrf
                                    @method('patch')
                                    <div class="form-row">
                                        <label>الحالة</label>
                                        <select name="status" class="select">
                                            @foreach (['pending', 'receiving_offers', 'driver_selected', 'driver_confirmed', 'driver_on_the_way', 'driver_arrived', 'trip_started', 'trip_completed', 'rated', 'cancelled'] as $option)
                                                <option value="{{ $option }}" @selected($ride->status === $option)>{{ $statusLabels[$option] ?? $option }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-row">
                                        <label>الأجرة</label>
                                        <input class="input" name="actual_fare" type="number" step="0.01" min="0" value="{{ $ride->actual_fare ?? $ride->fare_estimate }}">
                                    </div>
                                    <div class="form-row">
                                        <label>المسافة كم</label>
                                        <input class="input" name="distance_km" type="number" step="0.01" min="0" value="{{ $ride->distance_km }}">
                                    </div>
                                    <div class="form-row">
                                        <label>&nbsp;</label>
                                        <button class="btn primary" type="submit">حفظ</button>
                                    </div>
                                </form>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </div>
@endsection
