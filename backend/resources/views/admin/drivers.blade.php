@extends('admin.layout', ['title' => 'Drivers'])

@section('content')
    <div class="header">
        <div>
            <h1>Drivers</h1>
            <p class="subtitle">Approve new drivers, review their status, and keep the fleet healthy.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'All', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.drivers.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Pending</div><div class="value">{{ $pendingCount }}</div><div class="hint">Awaiting approval</div></div>
        <div class="metric"><div class="label">Approved</div><div class="value">{{ $approvedCount }}</div><div class="hint">Ready to receive trips</div></div>
        <div class="metric"><div class="label">Rejected</div><div class="value">{{ $rejectedCount }}</div><div class="hint">Needs review</div></div>
        <div class="metric"><div class="label">Online</div><div class="value">{{ $onlineCount }}</div><div class="hint">Currently available</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.drivers.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>⌕</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="Search by name, license, or plate">
                </label>
                <button class="btn primary" type="submit">Filter</button>
                <a class="btn" href="{{ route('admin.drivers.index') }}">Reset</a>
            </form>
        </div>

        @if ($drivers->isEmpty())
            <div class="empty">No drivers found.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>Driver</th>
                        <th>Vehicle</th>
                        <th>Approval</th>
                        <th>Online</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($drivers as $driver)
                        <tr>
                            <td>
                                <strong>{{ $driver->user?->name }}</strong>
                                <div class="muted">{{ $driver->user?->email }} · {{ $driver->user?->phone ?? 'No phone' }}</div>
                            </td>
                            <td>
                                <strong>{{ $driver->vehicle_type ?? 'Unknown vehicle' }}</strong>
                                <div class="muted">{{ $driver->vehicle_plate ?? 'No plate' }} · Rating {{ $driver->rating }}</div>
                            </td>
                            <td><span class="status {{ $driver->approval_status }}">{{ $driver->approval_status }}</span></td>
                            <td><span class="status {{ $driver->is_online ? 'approved' : 'inactive' }}">{{ $driver->is_online ? 'online' : 'offline' }}</span></td>
                            <td>
                                <div class="table-actions">
                                    <form method="post" action="{{ route('admin.drivers.approve', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn blue" type="submit">Approve</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.drivers.reject', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn danger" type="submit">Reject</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.drivers.toggle-online', $driver) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn" type="submit">Toggle online</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </div>
@endsection
