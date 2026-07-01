<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\RideRequest;
use Illuminate\View\View;

class AnalyticsController extends Controller
{
    public function index(): View
    {
        $commission = (float) (AppSetting::query()->where('key', 'commission_percent')->value('value') ?? 15);
        $baseQuery = RideRequest::query()->where('status', 'completed');
        $totalRevenue = (clone $baseQuery)->sum('platform_fee');
        $totalFare = (clone $baseQuery)->sum('actual_fare');

        return view('admin.analytics', [
            'commission' => $commission,
            'completedRides' => (clone $baseQuery)->count(),
            'grossRevenue' => $totalFare,
            'platformRevenue' => $totalRevenue,
            'averageFare' => (clone $baseQuery)->avg('actual_fare'),
            'averageDistance' => (clone $baseQuery)->avg('distance_km'),
            'monthly' => RideRequest::query()
                ->selectRaw('strftime("%Y-%m", completed_at) as month, COUNT(*) as rides, SUM(platform_fee) as revenue')
                ->where('status', 'completed')
                ->whereNotNull('completed_at')
                ->groupBy('month')
                ->orderBy('month', 'desc')
                ->limit(6)
                ->get(),
        ]);
    }
}
