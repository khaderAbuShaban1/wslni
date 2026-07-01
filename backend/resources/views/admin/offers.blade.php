@extends('admin.layout', ['title' => 'Offers'])

@section('content')
    <div class="header">
        <div>
            <h1>Offers</h1>
            <p class="subtitle">Create campaigns and keep promo codes active or disabled.</p>
        </div>
    </div>

    <section class="summary">
        <div class="metric"><div class="label">Active offers</div><div class="value">{{ $activeCount }}</div><div class="hint">Visible in the app</div></div>
        <div class="metric"><div class="label">Total offers</div><div class="value">{{ $offers->count() }}</div><div class="hint">Campaign library</div></div>
        <div class="metric"><div class="label">Promo type</div><div class="value">Discount</div><div class="hint">Supported with codes</div></div>
        <div class="metric"><div class="label">Toggle</div><div class="value">One click</div><div class="hint">Enable or disable quickly</div></div>
    </section>

    <section class="panels">
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Create offer</h2>
                        <p>Add promo codes for riders or seasonal campaigns.</p>
                    </div>
                </div>
            </div>
            <div style="padding: 0 18px 18px;">
                <form method="post" action="{{ route('admin.offers.store') }}" class="form-grid">
                    @csrf
                    <div class="form-row"><label>Title</label><input class="input" name="title" placeholder="Summer promo"></div>
                    <div class="form-row"><label>Code</label><input class="input" name="code" placeholder="SUMMER20"></div>
                    <div class="form-row">
                        <label>Type</label>
                        <select class="select" name="type">
                            <option value="discount">Discount</option>
                            <option value="fixed">Fixed</option>
                            <option value="free_ride">Free ride</option>
                        </select>
                    </div>
                    <div class="form-row"><label>Value</label><input class="input" name="value" type="number" step="0.01" min="0"></div>
                    <div class="form-row" style="grid-column: 1 / -1;">
                        <label>Notes</label>
                        <textarea class="textarea" name="notes" rows="3"></textarea>
                    </div>
                    <div class="form-row" style="align-self:end;">
                        <button class="btn primary" type="submit">Create offer</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    <div>
                        <h2>Existing offers</h2>
                        <p>Activate, pause, or review the campaign list.</p>
                    </div>
                </div>
            </div>
            @if ($offers->isEmpty())
                <div class="empty">No offers yet.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>Offer</th>
                            <th>Type</th>
                            <th>Status</th>
                            <th>Action</th>
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
                                <td><span class="status {{ $offer->is_active ? 'active' : 'inactive' }}">{{ $offer->is_active ? 'active' : 'inactive' }}</span></td>
                                <td>
                                    <form method="post" action="{{ route('admin.offers.toggle', $offer) }}">
                                        @csrf
                                        @method('patch')
                                        <button class="btn {{ $offer->is_active ? 'danger' : 'blue' }}" type="submit">{{ $offer->is_active ? 'Disable' : 'Enable' }}</button>
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
