@extends('admin.layout', ['title' => 'العروض'])

@section('content')
    <div class="header">
        <div>
            <h1>العروض</h1>
            <p class="subtitle">أنشئ حملات ترويجية وأبقِ أكواد الخصم مفعلة أو معطلة.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">العروض النشطة</div><div class="value">{{ $activeCount }}</div><div class="hint">ظاهرة داخل التطبيق</div></div>
        <div class="metric"><div class="label">إجمالي العروض</div><div class="value">{{ $offers->count() }}</div><div class="hint">مكتبة الحملات</div></div>
        <div class="metric"><div class="label">النوع</div><div class="value">خصم</div><div class="hint">مدعوم بالأكواد</div></div>
        <div class="metric"><div class="label">التبديل</div><div class="value">بضغطة</div><div class="hint">تفعيل أو تعطيل سريع</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>إنشاء عرض</h2>
                        <p>أضف أكواد خصم للركاب أو الحملات الموسمية.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.offers.store') }}" class="form-grid">
                    @csrf
                    <div class="form-row"><label>العنوان</label><input class="input" name="title" placeholder="عرض الصيف"></div>
                    <div class="form-row"><label>الكود</label><input class="input" name="code" placeholder="SUMMER20"></div>
                    <div class="form-row">
                        <label>النوع</label>
                        <select class="select" name="type">
                            <option value="discount">خصم</option>
                            <option value="fixed">مبلغ ثابت</option>
                            <option value="free_ride">رحلة مجانية</option>
                        </select>
                    </div>
                    <div class="form-row"><label>القيمة</label><input class="input" name="value" type="number" step="0.01" min="0"></div>
                    <div class="form-row" style="grid-column: 1 / -1;">
                        <label>ملاحظات</label>
                        <textarea class="textarea" name="notes" rows="3"></textarea>
                    </div>
                    <div class="form-row" style="align-self:end;">
                        <button class="btn primary" type="submit">إنشاء العرض</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>العروض الحالية</h2>
                        <p>فعّل العرض أو أوقفه وراجع القائمة.</p>
                    </div>
                </div>
            </div>
            @if ($offers->isEmpty())
                <div class="empty">لا توجد عروض بعد.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>العرض</th>
                            <th>النوع</th>
                            <th>الحالة</th>
                            <th>الإجراء</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($offers as $offer)
                            <tr>
                                <td>
                                    <strong>{{ $offer->title }}</strong>
                                    <div class="muted">{{ $offer->code }} · {{ $offer->value }}</div>
                                </td>
                                <td>{{ $offer->type }}</td>
                                <td><span class="status {{ $offer->is_active ? 'active' : 'inactive' }}">{{ $offer->is_active ? 'نشط' : 'متوقف' }}</span></td>
                                <td>
                                    <form method="post" action="{{ route('admin.offers.toggle', $offer) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn {{ $offer->is_active ? 'danger' : 'blue' }}" type="submit">{{ $offer->is_active ? 'تعطيل' : 'تفعيل' }}</button>
                                    </form>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            @endif
        </div>
    </section>
@endsection
