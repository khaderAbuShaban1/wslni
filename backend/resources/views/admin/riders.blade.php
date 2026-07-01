@extends('admin.layout', ['title' => 'Riders'])

@section('content')
    <div class="header">
        <div>
            <h1>Riders</h1>
            <p class="subtitle">Review customer accounts and suspend or activate them when needed.</p>
        </div>
        <div class="topline">
            @foreach (['all' => 'All', 'active' => 'Active', 'suspended' => 'Suspended'] as $key => $label)
                <a class="pill {{ $status === $key ? 'active' : '' }}" href="{{ route('admin.riders.index', ['status' => $key, 'search' => $search]) }}">{{ $label }}</a>
            @endforeach
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Active</div><div class="value">{{ $activeCount }}</div><div class="hint">Ready to book</div></div>
        <div class="metric"><div class="label">Suspended</div><div class="value">{{ $suspendedCount }}</div><div class="hint">Temporarily blocked</div></div>
        <div class="metric"><div class="label">Total riders</div><div class="value">{{ $riders->count() }}</div><div class="hint">Visible in current view</div></div>
        <div class="metric"><div class="label">Status filter</div><div class="value">{{ strtoupper($status) }}</div><div class="hint">Current scope</div></div>
    </section>

    <div class="panel">
        <div class="panel-header">
            <form class="controls" method="get" action="{{ route('admin.riders.index') }}">
                <input type="hidden" name="status" value="{{ $status }}">
                <label class="search">
                    <span>⌕</span>
                    <input type="search" name="search" value="{{ $search }}" placeholder="Search name or email">
                </label>
                <button class="btn primary" type="submit">Filter</button>
                <a class="btn" href="{{ route('admin.riders.index') }}">Reset</a>
            </form>
        </div>

        @if ($riders->isEmpty())
            <div class="empty">No riders found.</div>
        @else
            <table>
                <thead>
                    <tr>
                        <th>Rider</th>
                        <th>Contact</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($riders as $rider)
                        <tr>
                            <td>
                                <strong>{{ $rider->name }}</strong>
                                <div class="muted">Registered {{ $rider->created_at->format('M d, Y') }}</div>
                            </td>
                            <td>
                                <div>{{ $rider->email }}</div>
                                <div class="muted">{{ $rider->phone ?? 'No phone' }}</div>
                            </td>
                            <td><span class="status {{ $rider->account_status }}">{{ $rider->account_status }}</span></td>
                            <td>
                                <div class="table-actions">
                                    <form method="post" action="{{ route('admin.riders.activate', $rider) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn blue" type="submit">Activate</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.riders.suspend', $rider) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn danger" type="submit">Suspend</button>
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
