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

    public function updateStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        $profile = $user->driverProfile;
        abort_unless($profile !== null, 404, 'لم يتم العثور على ملف السائق.');

        $data = $request->validate([
            'is_online' => ['required', 'boolean'],
        ]);

        $profile->update(['is_online' => $data['is_online']]);

        return response()->json([
            'message' => $data['is_online'] ? 'أنت متصل الآن.' : 'تم إيقاف الاتصال.',
            'driver' => $profile->fresh(),
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
