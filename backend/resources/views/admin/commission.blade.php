@extends('admin.layout', ['title' => 'العمولة'])

@section('content')
    <div class="header">
        <div>
            <h1>العمولة</h1>
            <p class="subtitle">اضبط نسبة عمولة المنصة واحفظ نموذج الإيراد بشكل واضح.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">نسبة العمولة الحالية</div><div class="value">{{ $commission }}%</div><div class="hint">تُستخدم للحسابات الجديدة</div></div>
        <div class="metric"><div class="label">الرحلات المكتملة</div><div class="value">{{ $completedRides }}</div><div class="hint">قاعدة الإيراد</div></div>
        <div class="metric"><div class="label">إيراد المنصة</div><div class="value">{{ number_format((float) $totalRevenue, 2) }} ₪</div><div class="hint">بحسب الرسوم المخزنة</div></div>
        <div class="metric"><div class="label">النطاق</div><div class="value">0 - 100%</div><div class="hint">التحقق مفعل</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>تحديث العمولة</h2>
                    <p>غيّر حصة المنصة دون لمس الكود.</p>
                </div>
            </div>
        </div>
        <div style="padding: 0 18px 18px;">
            <form method="post" action="{{ route('admin.commission.update') }}" class="form-grid">
                @csrf
                <div class="form-row">
                    <label>نسبة العمولة</label>
                    <input class="input" type="number" step="0.01" min="0" max="100" name="commission_percent" value="{{ $commission }}">
                </div>
                <div class="form-row" style="align-self:end;">
                    <button class="btn primary" type="submit">حفظ العمولة</button>
                </div>
            </form>
        </div>
    </div>
@endsection
