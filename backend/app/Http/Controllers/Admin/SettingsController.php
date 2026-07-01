<?php

namespace App\Http\Controllers\Admin;

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

        return view('admin.commission', [
            'commission' => $commission,
            'totalRevenue' => RideRequest::query()->sum('platform_fee'),
            'completedRides' => RideRequest::query()->where('status', 'completed')->count(),
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
