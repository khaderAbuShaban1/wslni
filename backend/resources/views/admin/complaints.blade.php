@extends('admin.layout', ['title' => 'Complaints'])

@section('content')
    <div class="header">
        <div>
            <h1>Complaints</h1>
            <p class="subtitle">Handle support cases, attach them to rides, and resolve them cleanly.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Open</div><div class="value">{{ $openCount }}</div><div class="hint">Need attention</div></div>
        <div class="metric"><div class="label">Resolved</div><div class="value">{{ $resolvedCount }}</div><div class="hint">Closed cases</div></div>
        <div class="metric"><div class="label">Recent rides</div><div class="value">{{ $rides->count() }}</div><div class="hint">Available to attach</div></div>
        <div class="metric"><div class="label">Customers</div><div class="value">{{ $users->count() }}</div><div class="hint">Available reporters</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Log a complaint</h2>
                        <p>Record a support case and tie it to a rider or trip.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.complaints.store') }}" class="form-grid">
                    @csrf
                    <div class="form-row">
                        <label>Customer</label>
                        <select class="select" name="user_id">
                            @foreach ($users as $user)
                                <option value="{{ $user->id }}">{{ $user->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-row">
                        <label>Ride (optional)</label>
                        <select class="select" name="ride_request_id">
                            <option value="">None</option>
                            @foreach ($rides as $ride)
                                <option value="{{ $ride->id }}">#{{ $ride->id }} - {{ $ride->pickup_address }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-row">
                        <label>Category</label>
                        <input class="input" name="category" placeholder="Payment, behavior, delay, safety">
                    </div>
                    <div class="form-row">
                        <label>Message</label>
                        <textarea class="textarea" name="message" rows="3" placeholder="Write the complaint details"></textarea>
                    </div>
                    <div class="form-row" style="align-self:end;">
                        <button class="btn primary" type="submit">Save complaint</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Open cases</h2>
                        <p>Resolve or review complaints from the current queue.</p>
                    </div>
                </div>
            </div>
            @if ($complaints->isEmpty())
                <div class="empty">No complaints yet.</div>
            @else
                <div class="list">
                    @foreach ($complaints as $complaint)
                        <div class="list-item">
                            <div style="flex: 1;">
                                <strong>{{ $complaint->category }} · {{ $complaint->user?->name }}</strong>
                                <small>{{ $complaint->message }}</small>
                                <div class="muted" style="margin-top: 6px;">Status: <span class="status {{ $complaint->status }}">{{ $complaint->status }}</span></div>
                                @if ($complaint->rideRequest)
                                    <div class="muted">Ride #{{ $complaint->rideRequest->id }} · {{ $complaint->rideRequest->pickup_address }}</div>
                                @endif
                            </div>
                            <div style="min-width: 260px;">
                                @if ($complaint->status === 'open')
                                    <form method="post" action="{{ route('admin.complaints.resolve', $complaint) }}" class="form-row">
                                        @csrf
                                        @method('patch')
                                        <textarea class="textarea" name="resolution_note" rows="3" placeholder="Resolution note"></textarea>
                                        <button class="btn primary" type="submit">Resolve</button>
                                    </form>
                                @else
                                    <div class="muted">Resolved at {{ optional($complaint->resolved_at)->format('M d, H:i') }}</div>
                                @endif
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </section>
@endsection
