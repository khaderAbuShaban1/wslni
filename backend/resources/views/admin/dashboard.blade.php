@extends('admin.layout', ['title' => 'الرئيسية'])

@section('content')
    <div class="header">
        <div>
            <h1>الرئيسية</h1>
            <p class="subtitle">تابع التشغيل من مكان واحد وانتقل بسرعة إلى صفحات الإدارة المختلفة.</p>
        </div>
        <div class="topline">
            <a class="pill {{ $activeStatus === 'all' ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">كل الرحلات</a>
            @foreach (['requested' => 'مطلوبة', 'accepted' => 'مقبولة', 'in_progress' => 'قيد التنفيذ', 'completed' => 'مكتملة'] as $key => $label)
                <a class="pill {{ $activeStatus === $key ? 'active' : '' }}" href="{{ route('admin.dashboard', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric">
            <div class="label">السائقون</div>
            <div class="value">{{ $drivers }}</div>
            <div class="hint">{{ $onlineDrivers }} متصلون الآن</div>
        </div>
        <div class="metric">
            <div class="label">الركاب</div>
            <div class="value">{{ $customers }}</div>
            <div class="hint">مستخدمون جاهزون لطلب الرحلات</div>
        </div>
        <div class="metric">
            <div class="label">طلبات الرحلات</div>
            <div class="value">{{ $rides }}</div>
            <div class="hint">{{ $unassignedRides }} بانتظار الإسناد</div>
        </div>
        <div class="metric">
            <div class="label">الرحلات النشطة</div>
            <div class="value">{{ $activeRides }}</div>
            <div class="hint">رحلات مفتوحة حاليًا</div>
        </div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>طابور الرحلات الأخير</h2>
                        <p>ابحث حسب العنوان أو اسم الراكب ثم فلتر الحالة.</p>
                    </div>
                </div>
                <form class="controls" method="get" action="{{ route('admin.dashboard') }}">
                    <input type="hidden" name="status" value="{{ $activeStatus }}">
                    <label class="search">
                        <span>بحث</span>
                        <input type="search" name="search" value="{{ $search }}" placeholder="ابحث عن نقطة الانطلاق أو الوجهة أو اسم الراكب">
                    </label>
                    <button class="btn primary" type="submit">تصفية</button>
                    <a class="btn" href="{{ route('admin.dashboard') }}">إعادة ضبط</a>
                </form>
            </div>

            @if ($recentRides->isEmpty())
                <div class="empty">لا توجد رحلات مطابقة للفلتر الحالي.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>الرحلة</th>
                            <th>المسار</th>
                            <th>الحالة</th>
                            <th>الأجرة</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                            $statusLabels = [
                                'requested' => 'مطلوبة',
                                'accepted' => 'مقبولة',
                                'arrived' => 'وصل',
                                'in_progress' => 'قيد التنفيذ',
                                'completed' => 'مكتملة',
                                'cancelled' => 'ملغاة',
                            ];
                        @endphp
                        @foreach ($recentRides as $ride)
                            <tr>
                                <td>
                                    <strong>{{ $ride->customer?->name ?? 'راكب غير معروف' }}</strong>
                                    <div class="muted">{{ $ride->driver?->name ?? 'غير مسندة' }}</div>
                                </td>
                                <td>
                                    <strong>{{ $ride->pickup_address }}</strong>
                                    <div class="muted">إلى {{ $ride->dropoff_address }}</div>
                                </td>
                                <td>
                                    <span class="status {{ $ride->status }}">{{ $statusLabels[$ride->status] ?? $ride->status }}</span>
                                </td>
                                <td>
                                    <strong>{{ $ride->fare_estimate ? number_format((float) $ride->fare_estimate, 2) . ' ₪' : 'قيد التقدير' }}</strong>
                                    <div class="muted">{{ optional($ride->requested_at)->format('M d, H:i') ?? 'الآن' }}</div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            @endif
        </div>

        <div>
            <div class="panel">
                <div class="panel-header">
                    <div class="panel-title">
                        <div>
                            <h2>توزيع الحالات</h2>
                            <p>ملخص سريع لحركة الرحلات الحالية.</p>
                        </div>
                    </div>
                </div>
                <div class="list">
                    @foreach (['requested' => 'مطلوبة', 'accepted' => 'مقبولة', 'arrived' => 'وصل', 'in_progress' => 'قيد التنفيذ', 'completed' => 'مكتملة'] as $key => $label)
                        <div class="list-item">
                            <div>
                                <strong>{{ $label }}</strong>
                                <small>الرحلات في هذه المرحلة</small>
                            </div>
                            <span class="status-badge">{{ $statusCounts[$key] ?? 0 }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            <div class="stack">
                <div class="mini">
                    <div class="label">الرحلات غير المسندة</div>
                    <div class="value">{{ $unassignedRides }}</div>
                    <div class="note">طلبات تنتظر سائقًا.</div>
                </div>
                <div class="mini">
                    <div class="label">السائقون المتصلون</div>
                    <div class="value">{{ $onlineDrivers }}</div>
                    <div class="note">سائقون جاهزون لاستقبال الطلبات.</div>
                </div>
            </div>
        </div>
    </section>
@endsection
