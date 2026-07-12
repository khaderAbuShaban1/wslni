<?php

namespace App\Http\Controllers\Api;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RideOfferController extends Controller
{
    public function store(Request $request, RideRequest $ride): JsonResponse
    {
        $data = $request->validate([
            'driver_id' => ['required', 'exists:users,id'],
            'price' => ['required', 'numeric', 'min:1', 'max:99999'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'driver_id.required' => 'بيانات السائق مطلوبة.',
            'driver_id.exists' => 'حساب السائق غير موجود.',
            'price.required' => 'السعر مطلوب.',
            'price.numeric' => 'السعر يجب أن يكون رقمًا.',
            'price.min' => 'السعر يجب أن يكون أكبر من صفر.',
        ]);

        $result = DB::transaction(function () use ($ride, $data): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);

            if (! in_array($lockedRide->status, [RideStatus::Pending->value, RideStatus::ReceivingOffers->value], true)) {
                return ['error' => 'لا يمكن تقديم عرض على هذا الطلب حاليًا.'];
            }

            User::query()->lockForUpdate()->findOrFail($data['driver_id']);

            $hasActiveRide = RideRequest::query()
                ->where('driver_id', $data['driver_id'])
                ->whereIn('status', RideStatus::activeValues())
                ->exists();

            if ($hasActiveRide) {
                return ['error' => 'لديك رحلة نشطة. أنهِها أو ألغها قبل تقديم عرض جديد.'];
            }

            $offer = RideOffer::updateOrCreate(
                [
                    'ride_request_id' => $lockedRide->id,
                    'driver_id' => $data['driver_id'],
                ],
                [
                    'price' => $data['price'],
                    'notes' => $data['notes'] ?? null,
                    'status' => 'pending',
                ]
            );

            if ($lockedRide->status === RideStatus::Pending->value) {
                $lockedRide->update(['status' => RideStatus::ReceivingOffers->value]);
            }

            return ['offer' => $offer];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], 422);
        }

        return response()->json([
            'message' => 'تم إرسال عرض السعر بنجاح.',
            'offer' => $result['offer'],
        ], 201);
    }

    public function accept(RideRequest $ride, RideOffer $offer): JsonResponse
    {
        $result = DB::transaction(function () use ($ride, $offer): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);
            $lockedOffer = RideOffer::query()->lockForUpdate()->findOrFail($offer->id);

            if ($lockedOffer->ride_request_id !== $lockedRide->id) {
                return ['error' => 'هذا العرض لا يتبع لهذه الرحلة.', 'status' => 404];
            }

            if (! in_array($lockedRide->status, [RideStatus::Pending->value, RideStatus::ReceivingOffers->value], true)) {
                return ['error' => 'تم اختيار سائق لهذه الرحلة مسبقًا.', 'status' => 422];
            }

            User::query()->lockForUpdate()->findOrFail($lockedOffer->driver_id);

            $hasActiveRide = RideRequest::query()
                ->where('driver_id', $lockedOffer->driver_id)
                ->where('id', '!=', $lockedRide->id)
                ->whereIn('status', RideStatus::activeValues())
                ->exists();

            if ($hasActiveRide) {
                return ['error' => 'هذا السائق مرتبط برحلة أخرى حاليًا. اختر سائقًا آخر.', 'status' => 422];
            }

            RideOffer::query()
                ->where('ride_request_id', $lockedRide->id)
                ->where('id', '!=', $lockedOffer->id)
                ->update(['status' => 'inactive']);

            $lockedOffer->update(['status' => 'selected']);

            $lockedRide->update([
                'driver_id' => $lockedOffer->driver_id,
                'status' => RideStatus::DriverSelected->value,
                'actual_fare' => $lockedOffer->price,
            ]);

            return ['ride' => $lockedRide, 'offer' => $lockedOffer];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        return response()->json([
            'message' => 'تم قبول عرض السائق بنجاح.',
            'ride' => $result['ride']->fresh([
                'customer:id,name,phone',
                'driver:id,name,phone',
                'offers.driver:id,name,phone',
                'offers.driver.driverProfile',
            ]),
            'offer' => $result['offer']->fresh([
                'driver:id,name,phone',
                'driver.driverProfile',
            ]),
        ]);
    }

    public function acceptDriverOffer(RideRequest $ride, int $driver): JsonResponse
    {
        $offer = RideOffer::query()
            ->where('ride_request_id', $ride->id)
            ->where('driver_id', $driver)
            ->firstOrFail();

        return $this->accept($ride, $offer);
    }
}
