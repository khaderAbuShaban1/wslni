<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DriversController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim($request->string('search')->toString());
        $status = $request->string('status')->toString();

        $drivers = DriverProfile::query()
            ->with(['user:id,name,email,phone,account_status'])
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($nested) use ($search) {
                    $nested->whereHas('user', fn ($userQuery) => $userQuery->where('name', 'like', "%{$search}%"))
                        ->orWhere('license_number', 'like', "%{$search}%")
                        ->orWhere('vehicle_plate', 'like', "%{$search}%");
                });
            })
            ->when($status && $status !== 'all', fn ($query) => $query->where('approval_status', $status))
            ->latest()
            ->get();

        return view('admin.drivers', [
            'drivers' => $drivers,
            'search' => $search,
            'status' => $status ?: 'all',
            'pendingCount' => DriverProfile::query()->where('approval_status', 'pending')->count(),
            'approvedCount' => DriverProfile::query()->where('approval_status', 'approved')->count(),
            'rejectedCount' => DriverProfile::query()->where('approval_status', 'rejected')->count(),
            'onlineCount' => DriverProfile::query()->where('is_online', true)->count(),
        ]);
    }

    public function approve(DriverProfile $driverProfile): RedirectResponse
    {
        $driverProfile->update([
            'approval_status' => 'approved',
            'approved_at' => now(),
            'rejection_reason' => null,
        ]);

        return back()->with('status', 'Driver approved successfully.');
    }

    public function reject(Request $request, DriverProfile $driverProfile): RedirectResponse
    {
        $driverProfile->update([
            'approval_status' => 'rejected',
            'approved_at' => null,
            'rejection_reason' => $request->string('reason')->toString() ?: 'Rejected by admin review.',
        ]);

        return back()->with('status', 'Driver rejected successfully.');
    }

    public function toggleOnline(DriverProfile $driverProfile): RedirectResponse
    {
        $driverProfile->update([
            'is_online' => ! $driverProfile->is_online,
        ]);

        return back()->with('status', 'Driver online status updated.');
    }
}
