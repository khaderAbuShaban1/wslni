@extends('admin.layout', ['title' => 'Dashboard'])

@section('content')
    <div class="header">
        <div>
            <h1>Dashboard</h1>
            <p class="subtitle">Monitor the operation in one place and jump into the management screens fast.</p>
        </div>
        <div class="topline">
            <a class="pill {{ $activeStatus === 'all' ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">All rides</a>
            @foreach (['requested' => 'Requested', 'accepted' => 'Accepted', 'in_progress' => 'In progress', 'completed' => 'Completed'] as $key => $label)
                <a class="pill {{ $activeStatus === $key ? 'active' : '' }}" href="{{ route('admin.dashboard', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric">
            <div class="label">Drivers</div>
            <div class="value">{{ $drivers }}</div>
            <div class="hint">{{ $onlineDrivers }} online right now</div>
        </div>
        <div class="metric">
            <div class="label">Customers</div>
            <div class="value">{{ $customers }}</div>
            <div class="hint">Users ready to request rides</div>
        </div>
        <div class="metric">
            <div class="label">Ride Requests</div>
            <div class="value">{{ $rides }}</div>
            <div class="hint">{{ $unassignedRides }} waiting assignment</div>
        </div>
        <div class="metric">
            <div class="label">Active Rides</div>
            <div class="value">{{ $activeRides }}</div>
            <div class="hint">Open trips in motion</div>
        </div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Recent ride queue</h2>
                        <p>Search by address or rider, then narrow by status.</p>
                    </div>
                </div>
                <form class="controls" method="get" action="{{ route('admin.dashboard') }}">
                    <input type="hidden" name="status" value="{{ $activeStatus }}">
                    <label class="search">
                        <span>⌕</span>
                        <input type="search" name="search" value="{{ $search }}" placeholder="Search pickup, dropoff, customer, driver">
                    </label>
                    <button class="btn primary" type="submit">Filter</button>
                    <a class="btn" href="{{ route('admin.dashboard') }}">Reset</a>
                </form>
            </div>

            @if ($recentRides->isEmpty())
                <div class="empty">No rides match the current filter.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>Ride</th>
                            <th>Route</th>
                            <th>Status</th>
                            <th>Fare</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($recentRides as $ride)
                            <tr>
                                <td>
                                    <strong>{{ $ride->customer?->name ?? 'Unknown customer' }}</strong>
                                    <div class="muted">{{ $ride->driver?->name ?? 'Unassigned' }}</div>
                                </td>
                                <td>
                                    <strong>{{ $ride->pickup_address }}</strong>
                                    <div class="muted">to {{ $ride->dropoff_address }}</div>
                                </td>
                                <td>
                                    <span class="status {{ $ride->status }}">{{ str_replace('_', ' ', $ride->status) }}</span>
                                </td>
                                <td>
                                    <strong>{{ $ride->fare_estimate ? number_format((float) $ride->fare_estimate, 2) . ' USD' : 'Pending' }}</strong>
                                    <div class="muted">{{ optional($ride->requested_at)->format('M d, H:i') ?? 'Just now' }}</div>
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
                            <h2>Status breakdown</h2>
                            <p>Quick snapshot of the current ride flow.</p>
                        </div>
                    </div>
                </div>
                <div class="list">
                    @foreach (['requested' => 'Requested', 'accepted' => 'Accepted', 'arrived' => 'Arrived', 'in_progress' => 'In progress', 'completed' => 'Completed'] as $key => $label)
                        <div class="list-item">
                            <div>
                                <strong>{{ $label }}</strong>
                                <small>Rides currently in this stage</small>
                            </div>
                            <span class="status-badge">{{ $statusCounts[$key] ?? 0 }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            <div class="stack">
                <div class="mini">
                    <div class="label">Unassigned rides</div>
                    <div class="value">{{ $unassignedRides }}</div>
                    <div class="note">Requests waiting for a driver assignment.</div>
                </div>
                <div class="mini">
                    <div class="label">Online drivers</div>
                    <div class="value">{{ $onlineDrivers }}</div>
                    <div class="note">Drivers available to receive requests.</div>
                </div>
            </div>
        </div>
    </section>
@endsection
