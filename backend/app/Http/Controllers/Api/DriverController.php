<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function available(): JsonResponse
    {
        return response()->json([
            'drivers' => DriverProfile::query()->where('is_online', true)->latest()->get(),
        ]);
    }

    public function updateStatus(Request $request, DriverProfile $driver): JsonResponse
    {
        return response()->json([
            'message' => 'Driver status endpoint is ready for integration.',
            'driver' => $driver,
            'payload' => $request->all(),
        ]);
    }

    public function ratings(User $driver): JsonResponse
    {
        if ($driver->role !== 'driver') {
            return response()->json(['message' => 'الحساب المطلوب ليس حساب سائق.'], 404);
        }

        $ratings = RideRequest::query()
            ->where('driver_id', $driver->id)
            ->whereNotNull('rating')
            ->with('customer:id,name')
            ->latest('completed_at')
            ->get();

        $average = round((float) ($ratings->avg('rating') ?? 0), 2);

        return response()->json([
            'summary' => [
                'average' => $average,
                'count' => $ratings->count(),
                'five_star_count' => $ratings->where('rating', 5)->count(),
            ],
            'ratings' => $ratings->map(fn (RideRequest $ride) => [
                'ride_id' => $ride->id,
                'customer_name' => $ride->customer?->name ?? 'زبون',
                'rating' => $ride->rating,
                'comment' => $ride->rating_comment,
                'pickup_address' => $ride->pickup_address,
                'dropoff_address' => $ride->dropoff_address,
                'created_at' => $ride->completed_at?->toIso8601String() ?? $ride->updated_at?->toIso8601String(),
            ])->values(),
        ]);
    }
}
