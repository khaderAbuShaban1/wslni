<?php

namespace App\Http\Controllers\Admin;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->string('status')->toString();
        $search = trim($request->string('search')->toString());

        $ridesQuery = RideRequest::query()
            ->with(['customer:id,name,phone', 'driver:id,name,phone'])
            ->when($status && $status !== 'all', fn ($query) => $query->where('status', $status))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery->where('pickup_address', 'like', "%{$search}%")
                        ->orWhere('dropoff_address', 'like', "%{$search}%")
                        ->orWhereHas('customer', fn ($customerQuery) => $customerQuery->where('name', 'like', "%{$search}%"))
                        ->orWhereHas('driver', fn ($driverQuery) => $driverQuery->where('name', 'like', "%{$search}%"));
                });
            });

        $statusCounts = RideRequest::query()
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        return view('admin.dashboard', [
            'drivers' => User::query()->where('role', 'driver')->count(),
            'customers' => User::query()->where('role', 'customer')->count(),
            'rides' => RideRequest::query()->count(),
            'activeRides' => RideRequest::query()->whereIn('status', RideStatus::activeValues())->count(),
            'onlineDrivers' => DriverProfile::query()->where('is_online', true)->count(),
            'unassignedRides' => RideRequest::query()->whereNull('driver_id')->whereIn('status', [RideStatus::Pending->value, RideStatus::ReceivingOffers->value])->count(),
            'statusCounts' => $statusCounts,
            'recentRides' => $ridesQuery->latest('requested_at')->limit(8)->get(),
            'activeStatus' => $status ?: 'all',
            'search' => $search,
        ]);
    }
}
