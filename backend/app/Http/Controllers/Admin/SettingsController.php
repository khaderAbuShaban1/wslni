<?php

namespace App\Http\Controllers\Admin;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\RideRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SettingsController extends Controller
{
    public function edit(): View
    {
        $commission = (float) (AppSetting::query()->where('key', 'commission_percent')->value('value') ?? 15);
        // Only settled rides earned a fee. Summing every row counted fees left
        // on cancelled rides as revenue, which disagreed with the analytics page.
        $settledRides = RideRequest::query()
            ->whereIn('status', [RideStatus::TripCompleted->value, RideStatus::Rated->value]);

        return view('admin.commission', [
            'commission' => $commission,
            'totalRevenue' => (clone $settledRides)->sum('platform_fee'),
            'completedRides' => (clone $settledRides)->count(),
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'commission_percent' => ['required', 'numeric', 'min:0', 'max:100'],
        ]);

        AppSetting::query()->updateOrCreate(
            ['key' => 'commission_percent'],
            ['value' => $data['commission_percent']]
        );

        return back()->with('status', 'تم تحديث نسبة العمولة بنجاح.');
    }
}
