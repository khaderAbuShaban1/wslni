<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\RideRequest;

class RideController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(
            RideRequest::query()
                ->with([
                    'customer:id,name,phone',
                    'offers.driver:id,name,phone',
                ])
                ->where('status', 'requested')
                ->latest()
                ->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'customer_id' => ['required', 'exists:users,id'],
            'pickup_address' => ['required', 'string', 'max:255'],
            'dropoff_address' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'customer_id.required' => 'بيانات الزبون مطلوبة.',
            'customer_id.exists' => 'حساب الزبون غير موجود.',
            'pickup_address.required' => 'عنوان الانطلاق مطلوب.',
            'dropoff_address.required' => 'الوجهة مطلوبة.',
        ]);

        $ride = RideRequest::create([
            'customer_id' => $data['customer_id'],
            'status' => 'requested',
            'pickup_address' => $data['pickup_address'],
            'pickup_lat' => 0,
            'pickup_lng' => 0,
            'dropoff_address' => $data['dropoff_address'],
            'dropoff_lat' => 0,
            'dropoff_lng' => 0,
            'notes' => $data['notes'] ?? null,
            'requested_at' => now(),
        ]);

        return response()->json([
            'message' => 'تم إرسال طلب السيارة بنجاح.',
            'ride' => $ride,
        ], 201);
    }

    public function show(RideRequest $ride): JsonResponse
    {
        return response()->json(
            $ride->load([
                'customer:id,name,phone',
                'offers' => fn ($query) => $query
                    ->with('driver:id,name,phone')
                    ->latest(),
            ])
        );
    }

    public function update(Request $request, RideRequest $ride): JsonResponse
    {
        return response()->json([
            'message' => 'Ride update stub.',
            'ride' => $ride,
            'payload' => $request->all(),
        ]);
    }

    public function destroy(RideRequest $ride): JsonResponse
    {
        return response()->json(['message' => 'Ride deletion stub.', 'ride_id' => $ride->id]);
    }
}
