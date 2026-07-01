@extends('admin.layout', ['title' => 'الشكاوى'])

@section('content')
    <div class="header">
        <div>
            <h1>الشكاوى</h1>
            <p class="subtitle">سجّل بلاغات الدعم واربطها برحلة أو راكب ثم حلّها عند الانتهاء.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">مفتوحة</div><div class="value">{{ $openCount }}</div><div class="hint">تحتاج متابعة</div></div>
        <div class="metric"><div class="label">مغلقة</div><div class="value">{{ $resolvedCount }}</div><div class="hint">تم حلها</div></div>
        <div class="metric"><div class="label">الرحلات الحديثة</div><div class="value">{{ $rides->count() }}</div><div class="hint">متاحة للربط</div></div>
        <div class="metric"><div class="label">الركاب</div><div class="value">{{ $users->count() }}</div><div class="hint">مقدمو البلاغات المحتملون</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>إضافة شكوى</h2>
                        <p>سجّل الحالة واربطها براكب أو رحلة.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.complaints.store') }}" class="form-grid">
                    @csrf
                    <div class="form-row">
                        <label>الراكب</label>
                        <select class="select" name="user_id">
                            @foreach ($users as $user)
                                <option value="{{ $user->id }}">{{ $user->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-row">
                        <label>الرحلة (اختياري)</label>
                        <select class="select" name="ride_request_id">
                            <option value="">بدون</option>
                            @foreach ($rides as $ride)
                                <option value="{{ $ride->id }}">#{{ $ride->id }} - {{ $ride->pickup_address }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-row">
                        <label>الفئة</label>
                        <input class="input" name="category" placeholder="الدفع، السلوك، التأخير، الأمان">
                    </div>
                    <div class="form-row">
                        <label>الرسالة</label>
                        <textarea class="textarea" name="message" rows="3" placeholder="اكتب تفاصيل الشكوى"></textarea>
                    </div>
                    <div class="form-row" style="align-self:end;">
                        <button class="btn primary" type="submit">حفظ الشكوى</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>البلاغات المفتوحة</h2>
                        <p>راجع الشكاوى وحلّها من هنا.</p>
                    </div>
                </div>
            </div>
            @if ($complaints->isEmpty())
                <div class="empty">لا توجد شكاوى بعد.</div>
            @else
                <div class="list">
                    @foreach ($complaints as $complaint)
                        <div class="list-item">
                            <div style="flex: 1;">
                                <strong>{{ $complaint->category }} · {{ $complaint->user?->name }}</strong>
                                <small>{{ $complaint->message }}</small>
                                <div class="muted" style="margin-top: 6px;">الحالة: <span class="status {{ $complaint->status }}">{{ $complaint->status === 'resolved' ? 'مغلقة' : 'مفتوحة' }}</span></div>
                                @if ($complaint->rideRequest)
                                    <div class="muted">الرحلة #{{ $complaint->rideRequest->id }} · {{ $complaint->rideRequest->pickup_address }}</div>
                                @endif
                            </div>
                            <div style="min-width: 260px;">
                                @if ($complaint->status === 'open')
                                    <form method="post" action="{{ route('admin.complaints.resolve', $complaint) }}" class="form-row">
                                        @csrf
                                        @method('patch')
                                        <textarea class="textarea" name="resolution_note" rows="3" placeholder="ملاحظة الحل"></textarea>
                                        <button class="btn primary" type="submit">حل الشكوى</button>
                                    </form>
                                @else
                                    <div class="muted">تم الحل في {{ optional($complaint->resolved_at)->format('M d, H:i') }}</div>
                                @endif
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </section>
@endsection
