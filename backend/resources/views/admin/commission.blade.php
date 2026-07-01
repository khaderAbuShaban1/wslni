@extends('admin.layout', ['title' => 'Commission'])

@section('content')
    <div class="header">
        <div>
            <h1>Commission</h1>
            <p class="subtitle">Set the platform fee percentage and keep the revenue model clear.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Current commission</div><div class="value">{{ $commission }}%</div><div class="hint">Used for new ride calculations</div></div>
        <div class="metric"><div class="label">Completed rides</div><div class="value">{{ $completedRides }}</div><div class="hint">Revenue base</div></div>
        <div class="metric"><div class="label">Platform revenue</div><div class="value">{{ number_format((float) $totalRevenue, 2) }} USD</div><div class="hint">Based on stored ride fees</div></div>
        <div class="metric"><div class="label">Rule</div><div class="value">0-100%</div><div class="hint">Validation enforced</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <div class="panel-title">
                <div>
                    <h2>Update commission</h2>
                    <p>Change the platform share without touching code.</p>
                </div>
            </div>
        </div>
        <div style="padding: 0 18px 18px;">
            <form method="post" action="{{ route('admin.commission.update') }}" class="form-grid">
                @csrf
                <div class="form-row">
                    <label>Commission percent</label>
                    <input class="input" type="number" step="0.01" min="0" max="100" name="commission_percent" value="{{ $commission }}">
                </div>
                <div class="form-row" style="align-self:end;">
                    <button class="btn primary" type="submit">Save commission</button>
                </div>
            </form>
        </div>
    </div>
@endsection
