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
    public function me(Request $request): JsonResponse
    {
        $user = $this->driver($request);
        $user->loadMissing('driverProfile');

        return response()->json(['user' => $this->driverPayload($user)]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $this->driver($request);
        $profile = $user->driverProfile;
        abort_unless($profile !== null, 404, 'لم يتم العثور على ملف السائق.');

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'vehicle_type' => ['sometimes', 'string', 'max:100'],
            'vehicle_plate' => ['sometimes', 'string', 'max:30'],
        ], [
            'name.max' => 'الاسم طويل جدًا.',
            'phone.max' => 'رقم الجوال طويل جدًا.',
        ]);

        $userFields = array_intersect_key($data, array_flip(['name', 'phone']));
        $profileFields = array_intersect_key($data, array_flip(['vehicle_type', 'vehicle_plate']));

        if ($userFields) {
            $user->update($userFields);
        }
        if ($profileFields) {
            $profile->update($profileFields);
        }

        $user->loadMissing('driverProfile');

        return response()->json([
            'message' => 'تم تحديث البيانات بنجاح.',
            'user' => $this->driverPayload($user->fresh()),
        ]);
    }

    public function available(): JsonResponse
    {
        return response()->json([
            'drivers' => DriverProfile::query()
                ->where('is_online', true)
                ->where('approval_status', 'approved')
                ->latest()
                ->get(),
        ]);
    }

    public function updateStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        $profile = $user->driverProfile;
        abort_unless($profile !== null, 404, 'لم يتم العثور على ملف السائق.');

        if (! $profile->isApproved()) {
            return response()->json(['message' => 'حسابك كسائق لم يُعتمد بعد. لا يمكنك تغيير حالة الاتصال.'], 403);
        }

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
            ->with('customer:id,name,avatar_path')
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
                'customer_avatar' => $ride->customer?->avatar_path,
                'rating' => $ride->rating,
                'comment' => $ride->rating_comment,
                'pickup_address' => $ride->pickup_address,
                'dropoff_address' => $ride->dropoff_address,
                'created_at' => $ride->completed_at?->toIso8601String() ?? $ride->updated_at?->toIso8601String(),
            ])->values(),
        ]);
    }

    private function driver(Request $request): User
    {
        $user = $request->user();
        abort_unless($user?->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        return $user;
    }

    private function driverPayload(User $user): array
    {
        $user->loadMissing('driverProfile');

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'role' => $user->role,
            'wallet_balance' => (float) $user->wallet_balance,
            'driver_profile' => $user->driverProfile,
        ];
    }
}
