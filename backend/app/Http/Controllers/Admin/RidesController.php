<?php

namespace App\Http\Controllers\Admin;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\RideRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class RidesController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim($request->string('search')->toString());
        $status = $request->string('status')->toString();

        $rides = RideRequest::query()
            ->with(['customer:id,name,phone', 'driver:id,name,phone'])
            ->when($status && $status !== 'all', fn ($query) => $query->where('status', $status))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($nested) use ($search) {
                    $nested->where('pickup_address', 'like', "%{$search}%")
                        ->orWhere('dropoff_address', 'like', "%{$search}%")
                        ->orWhereHas('customer', fn ($userQuery) => $userQuery->where('name', 'like', "%{$search}%"))
                        ->orWhereHas('driver', fn ($userQuery) => $userQuery->where('name', 'like', "%{$search}%"));
                });
            })
            ->latest('requested_at')
            ->get();

        return view('admin.rides', [
            'rides' => $rides,
            'search' => $search,
            'status' => $status ?: 'all',
            'requestedCount' => RideRequest::query()->whereIn('status', [RideStatus::Pending->value, RideStatus::ReceivingOffers->value])->count(),
            'inProgressCount' => RideRequest::query()->where('status', RideStatus::TripStarted->value)->count(),
            'completedCount' => RideRequest::query()->whereIn('status', [RideStatus::TripCompleted->value, RideStatus::Rated->value])->count(),
        ]);
    }

    public function updateStatus(Request $request, RideRequest $rideRequest): RedirectResponse
    {
        $data = $request->validate([
            'status' => ['required', Rule::enum(RideStatus::class)],
            'actual_fare' => ['nullable', 'numeric', 'min:0'],
            'distance_km' => ['nullable', 'numeric', 'min:0'],
        ]);

        $currentStatus = RideStatus::tryFrom($rideRequest->status);
        $requestedStatus = RideStatus::from($data['status']);
        $allowed = $requestedStatus === RideStatus::Cancelled || $currentStatus?->next() === $requestedStatus;
        if (! $allowed) {
            return back()->withErrors(['status' => 'لا يمكن تخطي مراحل الرحلة.']);
        }

        $commissionPercent = (float) (AppSetting::query()->where('key', 'commission_percent')->value('value') ?? 15);
        $actualFare = $data['actual_fare'] ?? $rideRequest->fare_estimate;
        $platformFee = $actualFare !== null ? round(((float) $actualFare * $commissionPercent) / 100, 2) : null;

        $rideRequest->fill([
            'status' => $data['status'],
            'actual_fare' => $actualFare,
            'distance_km' => $data['distance_km'] ?? $rideRequest->distance_km,
            'commission_percent' => $commissionPercent,
            'platform_fee' => $platformFee,
            'accepted_at' => $requestedStatus === RideStatus::DriverConfirmed && $rideRequest->accepted_at === null ? now() : $rideRequest->accepted_at,
            'completed_at' => $requestedStatus === RideStatus::TripCompleted ? now() : $rideRequest->completed_at,
        ])->save();

        return back()->with('status', 'تم تحديث الرحلة بنجاح.');
    }
}
