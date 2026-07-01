@extends('admin.layout', ['title' => 'Trips'])

@section('content')
    <div class="header">
        <div>
            <h1>Trips</h1>
            <p class="subtitle">Track active trips, inspect completed rides, and update their state directly.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'All', 'requested' => 'Requested', 'accepted' => 'Accepted', 'in_progress' => 'In progress', 'completed' => 'Completed'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.rides.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Requested</div><div class="value">{{ $requestedCount }}</div><div class="hint">Waiting for assignment</div></div>
        <div class="metric"><div class="label">In progress</div><div class="value">{{ $inProgressCount }}</div><div class="hint">Currently moving</div></div>
        <div class="metric"><div class="label">Completed</div><div class="value">{{ $completedCount }}</div><div class="hint">Successfully closed</div></div>
        <div class="metric"><div class="label">Current filter</div><div class="value">{{ strtoupper($status) }}</div><div class="hint">Scope of the list</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.rides.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>⌕</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="Search address or customer">
                </label>
                <button class="btn primary" type="submit">Filter</button>
                <a class="btn" href="{{ route('admin.rides.index') }}">Reset</a>
            </form>
        </div>

        @if ($rides->isEmpty())
            <div class="empty">No trips found.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>Ride</th>
                        <th>Route</th>
                        <th>Status</th>
                        <th>Numbers</th>
                        <th>Quick update</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($rides as $ride)
                        <tr>
                            <td>
                                <strong>{{ $ride->customer?->name ?? 'Unknown' }}</strong>
                                <div class="muted">{{ $ride->driver?->name ?? 'Unassigned' }}</div>
                            </td>
                            <td>
                                <strong>{{ $ride->pickup_address }}</strong>
                                <div class="muted">to {{ $ride->dropoff_address }}</div>
                            </td>
                            <td><span class="status {{ $ride->status }}">{{ $ride->status }}</span></td>
                            <td>
                                <div>Fare: {{ $ride->actual_fare ?? $ride->fare_estimate ?? 'Pending' }}</div>
                                <div class="muted">Distance: {{ $ride->distance_km ?? 'N/A' }} km</div>
                            </td>
                            <td>
                                <form method="post" action="{{ route('admin.rides.status', $ride) }}" class="form-grid" style="grid-template-columns: 1fr 1fr; align-items:end;">
                                    @csrf
                                    @method('patch')
                                    <div class="form-row">
                                        <label>Status</label>
                                        <select name="status" class="select">
                                            @foreach (['requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled'] as $option)
                                                <option value="{{ $option }}" @selected($ride->status === $option)>{{ $option }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-row">
                                        <label>Fare</label>
                                        <input class="input" name="actual_fare" type="number" step="0.01" min="0" value="{{ $ride->actual_fare ?? $ride->fare_estimate }}">
                                    </div>
                                    <div class="form-row">
                                        <label>Distance km</label>
                                        <input class="input" name="distance_km" type="number" step="0.01" min="0" value="{{ $ride->distance_km }}">
                                    </div>
                                    <div class="form-row">
                                        <label>&nbsp;</label>
                                        <button class="btn primary" type="submit">Save</button>
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
