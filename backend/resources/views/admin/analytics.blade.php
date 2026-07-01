@extends('admin.layout', ['title' => 'Analytics'])

@section('content')
    <div class="header">
        <div>
            <h1>Analytics</h1>
            <p class="subtitle">Track revenue, trip volume, and the platform take rate over time.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Completed rides</div><div class="value">{{ $completedRides }}</div><div class="hint">Closed trips</div></div>
        <div class="metric"><div class="label">Gross fare</div><div class="value">{{ number_format((float) $grossRevenue, 2) }} USD</div><div class="hint">Before commission</div></div>
        <div class="metric"><div class="label">Platform revenue</div><div class="value">{{ number_format((float) $platformRevenue, 2) }} USD</div><div class="hint">At {{ $commission }}%</div></div>
        <div class="metric"><div class="label">Avg fare</div><div class="value">{{ number_format((float) $averageFare, 2) }} USD</div><div class="hint">Per completed ride</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Monthly performance</h2>
                        <p>Recent completed rides and platform revenue by month.</p>
                    </div>
                </div>
            </div>
            @if ($monthly->isEmpty())
                <div class="empty">No completed rides yet.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>Month</th>
                            <th>Rides</th>
                            <th>Revenue</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($monthly as $row)
                            <tr>
                                <td>{{ $row->month }}</td>
                                <td>{{ $row->rides }}</td>
                                <td>{{ number_format((float) $row->revenue, 2) }} USD</td>
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
                            <h2>Operational notes</h2>
                            <p>Quick reminders for the finance view.</p>
                        </div>
                    </div>
                </div>
                <div class="list">
                    <div class="list-item">
                        <div><strong>Commission source</strong><small>Stored in admin settings</small></div>
                        <span class="status-badge">{{ $commission }}%</span>
                    </div>
                    <div class="list-item">
                        <div><strong>Average distance</strong><small>On completed trips</small></div>
                        <span class="status-badge">{{ number_format((float) $averageDistance, 2) }} km</span>
                    </div>
                    <div class="list-item">
                        <div><strong>Revenue model</strong><small>Platform fee from ride totals</small></div>
                        <span class="status-badge">Dynamic</span>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection
