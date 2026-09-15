<?php

namespace App\Http\Controllers\Api;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\DriverProfile;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\FirebaseRealtimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RideController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
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
                // Open rides are visible to any authenticated user (drivers browse them).
                ->when($status === 'open', fn ($query) => $query->whereIn('status', [
                    RideStatus::Pending->value,
                    RideStatus::ReceivingOffers->value,
                ]))
                // All other queries are scoped to the authenticated user's own rides.
                ->when($status !== 'open', function ($query) use ($user, $status) {
                    $column = $user->role === 'driver' ? 'driver_id' : 'customer_id';
                    $query->where($column, $user->id);

                    return match ($status) {
                        'active' => $query->whereIn('status', RideStatus::activeValues()),
                        'all' => $query,
                        default => $query->where('status', $status),
                    };
                })
                ->latest()
                ->get()
        );
    }

    public function store(Request $request, FirebaseRealtimeService $firebase): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'يجب أن تكون زبونًا لطلب رحلة.');

        $hasActiveRide = RideRequest::query()
            ->where('customer_id', $user->id)
            ->whereIn('status', [
                RideStatus::Pending->value,
                RideStatus::ReceivingOffers->value,
                RideStatus::DriverSelected->value,
                ...RideStatus::activeValues(),
            ])
            ->exists();

        if ($hasActiveRide) {
            return response()->json([
                'message' => 'لديك رحلة نشطة بالفعل. أكملها أو ألغها قبل طلب رحلة جديدة.',
            ], 422);
        }

        $data = $request->validate([
            'pickup_address' => ['required', 'string', 'max:255'],
            'dropoff_address' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'pickup_address.required' => 'عنوان الانطلاق مطلوب.',
            'dropoff_address.required' => 'الوجهة مطلوبة.',
        ]);

        $ride = RideRequest::create([
            'customer_id' => $user->id,
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

        $firebase->syncRide($ride);

        return response()->json([
            'message' => 'تم إرسال طلب السيارة بنجاح.',
            'ride' => $ride,
        ], 201);
    }

    public function show(Request $request, RideRequest $ride): JsonResponse
    {
        $user = $request->user();
        abort_unless(
            (int) $ride->customer_id === $user->id || (int) $ride->driver_id === $user->id,
            403,
            'ليس لديك صلاحية لعرض هذه الرحلة.',
        );

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
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        $data = $request->validate([
            'status' => ['required', 'in:driver_on_the_way,driver_arrived,trip_started,trip_completed,cancelled'],
        ], [
            'status.required' => 'حالة الرحلة مطلوبة.',
            'status.in' => 'حالة الرحلة غير صالحة.',
        ]);

        $result = DB::transaction(function () use ($ride, $data, $user): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);

            if ((int) $lockedRide->driver_id !== $user->id) {
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
                $fare = round((float) $lockedRide->actual_fare, 2);
                if ($fare <= 0) {
                    return ['error' => 'لا يمكن إنهاء الرحلة قبل تحديد الأجرة.', 'status' => 422];
                }

                $users = User::query()
                    ->whereIn('id', [$lockedRide->customer_id, $lockedRide->driver_id])
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');
                $customer = $users->get($lockedRide->customer_id);
                $driver = $users->get($lockedRide->driver_id);
                if (! $customer || ! $driver) {
                    return ['error' => 'تعذر العثور على محفظة الزبون أو السائق.', 'status' => 422];
                }
                if ((float) $customer->wallet_balance < $fare) {
                    return ['error' => 'رصيد محفظة الزبون غير كافٍ لإكمال الرحلة.', 'status' => 422];
                }

                $commissionPercent = (float) (AppSetting::query()
                    ->where('key', 'commission_percent')
                    ->value('value') ?? 15);
                $platformFee = round($fare * $commissionPercent / 100, 2);
                $driverEarning = round($fare - $platformFee, 2);
                $customerBalance = round((float) $customer->wallet_balance - $fare, 2);
                $driverBalance = round((float) $driver->wallet_balance + $driverEarning, 2);

                $customer->update(['wallet_balance' => $customerBalance]);
                $driver->update(['wallet_balance' => $driverBalance]);
                WalletTransaction::create([
                    'user_id' => $customer->id,
                    'ride_request_id' => $lockedRide->id,
                    'type' => 'ride_fare_debit',
                    'amount' => -$fare,
                    'balance_after' => $customerBalance,
                    'description' => 'خصم أجرة الرحلة',
                ]);
                WalletTransaction::create([
                    'user_id' => $driver->id,
                    'ride_request_id' => $lockedRide->id,
                    'type' => 'driver_earning_credit',
                    'amount' => $driverEarning,
                    'balance_after' => $driverBalance,
                    'description' => 'صافي أرباح الرحلة',
                ]);
                WalletTransaction::create([
                    'ride_request_id' => $lockedRide->id,
                    'type' => 'platform_commission',
                    'amount' => $platformFee,
                    'description' => 'عمولة التطبيق',
                ]);

                $updates['commission_percent'] = $commissionPercent;
                $updates['platform_fee'] = $platformFee;
                $updates['completed_at'] = now();
            }

            $lockedRide->update($updates);

            if ($data['status'] === 'cancelled') {
                RideOffer::query()
                    ->where('ride_request_id', $lockedRide->id)
                    ->where('driver_id', $user->id)
                    ->where('status', 'accepted')
                    ->update(['status' => 'cancelled']);
            }

            return ['ride' => $lockedRide];
        });

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], $result['status']);
        }

        $syncedRide = $result['ride']->fresh();

        return response()->json([
            'message' => 'تم تحديث حالة الرحلة بنجاح.',
            'ride' => $syncedRide->load([
                'customer:id,name,phone',
                'driver:id,name,phone',
                'offers.driver:id,name,phone',
                'offers.driver.driverProfile',
            ]),
        ]);
    }

    public function driverConfirmation(Request $request, RideRequest $ride): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'driver', 403, 'هذا الإجراء متاح للسائقين فقط.');

        $data = $request->validate([
            'accepted' => ['required', 'boolean'],
        ]);

        $result = DB::transaction(function () use ($ride, $data, $user): array {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);
            if ($lockedRide->status !== RideStatus::DriverSelected->value || (int) $lockedRide->driver_id !== $user->id) {
                return ['error' => 'لا يمكن الرد على هذا الطلب في حالته الحالية.', 'status' => 422];
            }

            $selectedOffer = RideOffer::query()
                ->where('ride_request_id', $lockedRide->id)
                ->where('driver_id', $user->id)
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

        $syncedRide = $result['ride']->fresh();

        return response()->json(['ride' => $syncedRide->load(['customer:id,name,phone', 'driver.driverProfile'])]);
    }

    public function rate(Request $request, RideRequest $ride): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'التقييم متاح للزبائن فقط.');

        $data = $request->validate([
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        if ((int) $ride->customer_id !== $user->id || $ride->status !== RideStatus::TripCompleted->value) {
            return response()->json(['message' => 'لا يمكن تقييم هذه الرحلة في حالتها الحالية.'], 422);
        }

        $ride->update([
            'status' => RideStatus::Rated->value,
            'rating' => $data['rating'],
            'rating_comment' => $data['comment'] ?? null,
        ]);

        $averageRating = RideRequest::query()
            ->where('driver_id', $ride->driver_id)
            ->whereNotNull('rating')
            ->avg('rating');
        DriverProfile::query()
            ->where('user_id', $ride->driver_id)
            ->update(['rating' => round((float) ($averageRating ?? 5), 2)]);

        $syncedRide = $ride->fresh();

        return response()->json(['message' => 'تم حفظ تقييمك.', 'ride' => $syncedRide]);
    }

    public function destroy(Request $request, RideRequest $ride): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'customer', 403, 'إلغاء الرحلة متاح للزبائن فقط.');
        abort_unless((int) $ride->customer_id === $user->id, 403, 'هذه الرحلة ليست رحلتك.');

        $customerCancellable = [
            RideStatus::Pending->value,
            RideStatus::ReceivingOffers->value,
            RideStatus::DriverSelected->value,
        ];

        if (! in_array($ride->status, $customerCancellable, true)) {
            return response()->json([
                'message' => 'لا يمكن إلغاء الرحلة في حالتها الحالية. تواصل مع الدعم.',
            ], 422);
        }

        DB::transaction(function () use ($ride) {
            $lockedRide = RideRequest::query()->lockForUpdate()->findOrFail($ride->id);

            // Deactivate all pending/selected offers
            RideOffer::query()
                ->where('ride_request_id', $lockedRide->id)
                ->whereIn('status', ['pending', 'selected', 'inactive'])
                ->update(['status' => 'cancelled']);

            $lockedRide->update([
                'status' => RideStatus::Cancelled->value,
                'driver_id' => null,
                'actual_fare' => null,
            ]);
        });

        return response()->json([
            'message' => 'تم إلغاء الرحلة بنجاح.',
            'ride' => $ride->fresh(),
        ]);
    }
}
