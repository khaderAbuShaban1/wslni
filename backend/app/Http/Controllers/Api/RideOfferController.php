<?php

namespace App\Http\Controllers\Api;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use App\Services\RideExpiryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RideOfferController extends Controller
{
    public function store(Request $request, RideRequest $ride): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'تقديم العروض متاح للسائقين فقط.');

        $profile = $user->driverProfile;
        if (! $profile || ! $profile->isApproved()) {
            return response()->json(['message' => 'حسابك كسائق لم يُعتمد بعد. لا يمكنك تقديم عروض.'], 403);
        }

        $data = $request->validate([
            'price' => ['required', 'numeric', 'min:1', 'max:99999'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'price.required' => 'السعر مطلوب.',
            'price.numeric' => 'السعر يجب أن يكون رقمًا.',
            'price.min' => 'السعر يجب أن يكون أكبر من صفر.',
        ]);

        $result = DB::transaction(function () use ($ride, $data, $user): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);

            if (RideExpiryService::isDue($lockedRide)) {
                return ['error' => 'انتهت مهلة هذا الطلب.'];
            }

            if (! in_array($lockedRide->status, [RideStatus::Pending->value, RideStatus::ReceivingOffers->value], true)) {
                return ['error' => 'لا يمكن تقديم عرض على هذا الطلب حاليًا.'];
            }

            $hasActiveRide = RideRequest::query()
                ->where('driver_id', $user->id)
                ->whereIn('status', RideStatus::activeValues())
                ->exists();

            if ($hasActiveRide) {
                return ['error' => 'لديك رحلة نشطة. أنهِها أو ألغها قبل تقديم عرض جديد.'];
            }

            $offer = RideOffer::updateOrCreate(
                [
                    'ride_request_id' => $lockedRide->id,
                    'driver_id' => $user->id,
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

    public function accept(Request $request, RideRequest $ride, RideOffer $offer): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'قبول العروض متاح للزبائن فقط.');
        abort_unless((int) $ride->customer_id === $user->id, 403, 'هذه الرحلة ليست رحلتك.');

        $result = DB::transaction(function () use ($ride, $offer, $user): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);
            $lockedOffer = RideOffer::query()->lockForUpdate()->findOrFail($offer->id);

            if ($lockedOffer->ride_request_id !== $lockedRide->id) {
                return ['error' => 'هذا العرض لا يتبع لهذه الرحلة.', 'status' => 404];
            }

            if (RideExpiryService::isDue($lockedRide)) {
                return ['error' => 'انتهت مهلة هذا الطلب. يمكنك إنشاء رحلة جديدة.', 'status' => 422];
            }

            if (! in_array($lockedRide->status, [RideStatus::Pending->value, RideStatus::ReceivingOffers->value], true)) {
                return ['error' => 'تم اختيار سائق لهذه الرحلة مسبقًا.', 'status' => 422];
            }

            $users = User::query()
                ->whereIn('id', [$lockedOffer->driver_id, $lockedRide->customer_id])
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');
            $customer = $users->get($lockedRide->customer_id);
            if (! $customer || (float) $customer->wallet_balance < (float) $lockedOffer->price) {
                return ['error' => 'رصيد محفظتك غير كافٍ لقبول هذا العرض.', 'status' => 422];
            }

            $driverProfile = \App\Models\DriverProfile::query()
                ->where('user_id', $lockedOffer->driver_id)
                ->first();

            if (! $driverProfile || ! $driverProfile->isApproved()) {
                return ['error' => 'هذا السائق لم يعد معتمدًا. اختر سائقًا آخر.', 'status' => 422];
            }

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
                // The customer's trip screen opens straight from this response
                // and shows the car and plate; without the profile they read
                // "غير متوفر" until the Firebase mirror catches up.
                'driver.driverProfile',
                'offers.driver:id,name,phone',
                'offers.driver.driverProfile',
            ]),
            'offer' => $result['offer']->fresh([
                'driver:id,name,phone',
                'driver.driverProfile',
            ]),
        ]);
    }

    public function acceptDriverOffer(Request $request, RideRequest $ride, int $driver): JsonResponse
    {
        $offer = RideOffer::query()
            ->where('ride_request_id', $ride->id)
            ->where('driver_id', $driver)
            ->firstOrFail();

        return $this->accept($request, $ride, $offer);
    }
}
