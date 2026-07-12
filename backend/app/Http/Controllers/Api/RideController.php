<?php

namespace App\Http\Controllers\Api;

use App\Enums\RideStatus;
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
        $status = $request->query('status', RideStatus::Pending->value);

        return response()->json(
            RideRequest::query()
                ->with([
                    'customer:id,name,phone',
                    'driver:id,name,phone',
                    'driver.driverProfile',
                    'offers.driver:id,name,phone',
                    'offers.driver.driverProfile',
                ])
                ->when($status === 'active', fn ($query) => $query->whereIn('status', RideStatus::activeValues()))
                ->when($status === 'open', fn ($query) => $query->whereIn('status', [
                    RideStatus::Pending->value,
                    RideStatus::ReceivingOffers->value,
                ]))
                ->when(! in_array($status, ['all', 'active', 'open'], true), fn ($query) => $query->where('status', $status))
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
            'status' => RideStatus::Pending->value,
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
                    ->with([
                        'driver:id,name,phone',
                        'driver.driverProfile',
                    ])
                    ->latest(),
            ])
        );
    }

    public function update(Request $request, RideRequest $ride): JsonResponse
    {
        $data = $request->validate([
            'driver_id' => ['required', 'exists:users,id'],
            'status' => ['required', 'in:driver_on_the_way,driver_arrived,trip_started,trip_completed,cancelled'],
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
                RideStatus::DriverConfirmed->value => [RideStatus::DriverOnTheWay->value, RideStatus::Cancelled->value],
                RideStatus::DriverOnTheWay->value => [RideStatus::DriverArrived->value, RideStatus::Cancelled->value],
                RideStatus::DriverArrived->value => [RideStatus::TripStarted->value, RideStatus::Cancelled->value],
                RideStatus::TripStarted->value => [RideStatus::TripCompleted->value, RideStatus::Cancelled->value],
            ];

            if (! in_array($data['status'], $allowedTransitions[$lockedRide->status] ?? [], true)) {
                return ['error' => 'لا يمكن نقل الرحلة إلى هذه الحالة الآن.', 'status' => 422];
            }

            $updates = ['status' => $data['status']];
            if ($data['status'] === RideStatus::TripCompleted->value) {
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
                'offers.driver.driverProfile',
            ]),
        ]);
    }

    public function driverConfirmation(Request $request, RideRequest $ride): JsonResponse
    {
        $data = $request->validate([
            'driver_id' => ['required', 'exists:users,id'],
            'accepted' => ['required', 'boolean'],
        ]);

        $result = DB::transaction(function () use ($ride, $data): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);
            if ($lockedRide->status !== RideStatus::DriverSelected->value || (int) $lockedRide->driver_id !== (int) $data['driver_id']) {
                return ['error' => 'لا يمكن الرد على هذا الطلب في حالته الحالية.', 'status' => 422];
            }

            $selectedOffer = RideOffer::query()
                ->where('ride_request_id', $lockedRide->id)
                ->where('driver_id', $data['driver_id'])
                ->firstOrFail();

            if ($data['accepted']) {
                $selectedOffer->update(['status' => 'accepted']);
                $lockedRide->update([
                    'status' => RideStatus::DriverConfirmed->value,
                    'accepted_at' => now(),
                ]);
            } else {
                $selectedOffer->update(['status' => 'rejected']);
                RideOffer::query()
                    ->where('ride_request_id', $lockedRide->id)
                    ->where('status', 'inactive')
                    ->update(['status' => 'pending']);
                $lockedRide->update([
                    'driver_id' => null,
                    'status' => RideStatus::ReceivingOffers->value,
                    'actual_fare' => null,
                ]);
            }

            return ['ride' => $lockedRide];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json(['ride' => $result['ride']->fresh(['customer:id,name,phone', 'driver.driverProfile'])]);
    }

    public function rate(Request $request, RideRequest $ride): JsonResponse
    {
        $data = $request->validate([
            'customer_id' => ['required', 'exists:users,id'],
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        if ((int) $ride->customer_id !== (int) $data['customer_id'] || $ride->status !== RideStatus::TripCompleted->value) {
            return response()->json(['message' => 'لا يمكن تقييم هذه الرحلة في حالتها الحالية.'], 422);
        }

        $ride->update([
            'status' => RideStatus::Rated->value,
            'rating' => $data['rating'],
            'rating_comment' => $data['comment'] ?? null,
        ]);

        return response()->json(['message' => 'تم حفظ تقييمك.', 'ride' => $ride->fresh()]);
    }

    public function destroy(RideRequest $ride): JsonResponse
    {
        return response()->json(['message' => 'Ride deletion stub.', 'ride_id' => $ride->id]);
    }
}
