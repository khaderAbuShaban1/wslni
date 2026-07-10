<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RideOffer;
use App\Models\RideRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RideController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $customerId = $request->query('customer_id');
        $driverId = $request->query('driver_id');
        $status = $request->query('status', 'requested');

        return response()->json(
            RideRequest::query()
                ->with([
                    'customer:id,name,phone',
                    'offers.driver:id,name,phone',
                ])
                ->when($status === 'active', fn ($query) => $query->whereIn('status', [
                    'accepted',
                    'arrived',
                    'in_progress',
                ]))
                ->when(! in_array($status, ['all', 'active'], true), fn ($query) => $query->where('status', $status))
                ->when($customerId, fn ($query) => $query->where('customer_id', $customerId))
                ->when($driverId, fn ($query) => $query->where('driver_id', $driverId))
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
        $data = $request->validate([
            'driver_id' => ['required', 'exists:users,id'],
            'status' => ['required', 'in:arrived,in_progress,completed,cancelled'],
        ], [
            'driver_id.required' => 'بيانات السائق مطلوبة.',
            'driver_id.exists' => 'حساب السائق غير موجود.',
            'status.required' => 'حالة الرحلة مطلوبة.',
            'status.in' => 'حالة الرحلة غير صالحة.',
        ]);

        $result = DB::transaction(function () use ($ride, $data): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);

            if ((int) $lockedRide->driver_id !== (int) $data['driver_id']) {
                return ['error' => 'هذه الرحلة غير مرتبطة بهذا السائق.', 'status' => 403];
            }

            $allowedTransitions = [
                'accepted' => ['arrived', 'cancelled'],
                'arrived' => ['in_progress', 'cancelled'],
                'in_progress' => ['completed', 'cancelled'],
            ];

            if (! in_array($data['status'], $allowedTransitions[$lockedRide->status] ?? [], true)) {
                return ['error' => 'لا يمكن نقل الرحلة إلى هذه الحالة الآن.', 'status' => 422];
            }

            $updates = ['status' => $data['status']];
            if ($data['status'] === 'completed') {
                $updates['completed_at'] = now();
            }

            $lockedRide->update($updates);

            if ($data['status'] === 'cancelled') {
                RideOffer::query()
                    ->where('ride_request_id', $lockedRide->id)
                    ->where('driver_id', $data['driver_id'])
                    ->where('status', 'accepted')
                    ->update(['status' => 'cancelled']);
            }

            return ['ride' => $lockedRide];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'message' => 'تم تحديث حالة الرحلة بنجاح.',
            'ride' => $result['ride']->fresh([
                'customer:id,name,phone',
                'driver:id,name,phone',
                'offers.driver:id,name,phone',
            ]),
        ]);
    }

    public function destroy(RideRequest $ride): JsonResponse
    {
        return response()->json(['message' => 'Ride deletion stub.', 'ride_id' => $ride->id]);
    }
}
