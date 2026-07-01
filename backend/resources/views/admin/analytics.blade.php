@extends('admin.layout', ['title' => 'الإحصائيات'])

@section('content')
    <div class="header">
        <div>
            <h1>الإحصائيات</h1>
            <p class="subtitle">راقب الإيرادات، حجم الرحلات، ونسبة المنصة عبر الزمن.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">الرحلات المكتملة</div><div class="value">{{ $completedRides }}</div><div class="hint">رحلات مغلقة</div></div>
        <div class="metric"><div class="label">إجمالي الأجرة</div><div class="value">{{ number_format((float) $grossRevenue, 2) }} ₪</div><div class="hint">قبل العمولة</div></div>
        <div class="metric"><div class="label">إيراد المنصة</div><div class="value">{{ number_format((float) $platformRevenue, 2) }} ₪</div><div class="hint">عند نسبة {{ $commission }}%</div></div>
        <div class="metric"><div class="label">متوسط الأجرة</div><div class="value">{{ number_format((float) $averageFare, 2) }} ₪</div><div class="hint">لكل رحلة مكتملة</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>الأداء الشهري</h2>
                        <p>الرحلات المكتملة والإيراد حسب الشهر.</p>
                    </div>
                </div>
            </div>
            @if ($monthly->isEmpty())
                <div class="empty">لا توجد رحلات مكتملة بعد.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>الشهر</th>
                            <th>الرحلات</th>
                            <th>الإيراد</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($monthly as $row)
                            <tr>
                                <td>{{ $row->month }}</td>
                                <td>{{ $row->rides }}</td>
                                <td>{{ number_format((float) $row->revenue, 2) }} ₪</td>
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
                            <h2>ملاحظات تشغيلية</h2>
                            <p>تذكيرات سريعة لعرض المالية.</p>
                        </div>
                    </div>
                </div>
                <div class="list">
                    <div class="list-item">
                        <div><strong>مصدر العمولة</strong><small>محفوظ في إعدادات الإدارة</small></div>
                        <span class="status-badge">{{ $commission }}%</span>
                    </div>
                    <div class="list-item">
                        <div><strong>متوسط المسافة</strong><small>على الرحلات المكتملة</small></div>
                        <span class="status-badge">{{ number_format((float) $averageDistance, 2) }} كم</span>
                    </div>
                    <div class="list-item">
                        <div><strong>نموذج الإيراد</strong><small>رسوم منصة من إجمالي الرحلة</small></div>
                        <span class="status-badge">ديناميكي</span>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection
