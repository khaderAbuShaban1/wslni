<?php

namespace App\Http\Controllers\Admin;

use App\Enums\RideStatus;
use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\NotificationDispatcher;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class RidesController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim($request->string('search')->toString());
        $status = $request->string('status')->toString();

        $rides = RideRequest::query()
            ->with(['customer:id,name,phone', 'driver:id,name,phone'])
            ->when($status && $status !== 'all', fn ($query) => $query->where('status', $status))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($nested) use ($search) {
                    $nested->where('pickup_address', 'like', "%{$search}%")
                        ->orWhere('dropoff_address', 'like', "%{$search}%")
                        ->orWhereHas('customer', fn ($userQuery) => $userQuery->where('name', 'like', "%{$search}%"))
                        ->orWhereHas('driver', fn ($userQuery) => $userQuery->where('name', 'like', "%{$search}%"));
                });
            })
            ->latest('requested_at')
            ->get();

        return view('admin.rides', [
            'rides' => $rides,
            'search' => $search,
            'status' => $status ?: 'all',
            'requestedCount' => RideRequest::query()->whereIn('status', [RideStatus::Pending->value, RideStatus::ReceivingOffers->value])->count(),
            'inProgressCount' => RideRequest::query()->where('status', RideStatus::TripStarted->value)->count(),
            'completedCount' => RideRequest::query()->whereIn('status', [RideStatus::TripCompleted->value, RideStatus::Rated->value])->count(),
        ]);
    }

    public function updateStatus(
        Request $request,
        RideRequest $rideRequest,
        NotificationDispatcher $notifications,
    ): RedirectResponse {
        $data = $request->validate([
            'status' => ['required', Rule::enum(RideStatus::class)],
            'actual_fare' => ['nullable', 'numeric', 'min:0'],
            'distance_km' => ['nullable', 'numeric', 'min:0'],
        ]);

        $currentStatus = RideStatus::tryFrom($rideRequest->status);
        $requestedStatus = RideStatus::from($data['status']);
        $allowed = $requestedStatus === RideStatus::Cancelled || $currentStatus?->next() === $requestedStatus;
        if (! $allowed) {
            return back()->withErrors(['status' => 'لا يمكن تخطي مراحل الرحلة.']);
        }

        if ($requestedStatus === RideStatus::Cancelled) {
            return $this->cancel($rideRequest, $currentStatus, $notifications);
        }

        $commissionPercent = (float) (AppSetting::query()->where('key', 'commission_percent')->value('value') ?? 15);
        $actualFare = $data['actual_fare'] ?? $rideRequest->fare_estimate;
        $platformFee = $actualFare !== null ? round(((float) $actualFare * $commissionPercent) / 100, 2) : null;

        $rideRequest->fill([
            'status' => $data['status'],
            'actual_fare' => $actualFare,
            'distance_km' => $data['distance_km'] ?? $rideRequest->distance_km,
            'commission_percent' => $commissionPercent,
            'platform_fee' => $platformFee,
            'accepted_at' => $requestedStatus === RideStatus::DriverConfirmed && $rideRequest->accepted_at === null ? now() : $rideRequest->accepted_at,
            'completed_at' => $requestedStatus === RideStatus::TripCompleted ? now() : $rideRequest->completed_at,
        ])->save();

        return back()->with('status', 'تم تحديث الرحلة بنجاح.');
    }

    /**
     * A cancelled ride must leave nobody paid: no fare, no commission, and any
     * money a settled ride already moved is returned to where it came from.
     */
    private function cancel(
        RideRequest $rideRequest,
        ?RideStatus $currentStatus,
        NotificationDispatcher $notifications,
    ): RedirectResponse {
        $wasSettled = in_array($currentStatus, [RideStatus::TripCompleted, RideStatus::Rated], true);
        $driverId = (int) $rideRequest->driver_id;
        $error = null;

        DB::transaction(function () use ($rideRequest, $wasSettled, &$error): void {
            $ride = RideRequest::query()->lockForUpdate()->findOrFail($rideRequest->id);

            if ($wasSettled && $ride->actual_fare !== null && $ride->driver_id !== null) {
                $fare = round((float) $ride->actual_fare, 2);
                $driverEarning = round($fare - (float) $ride->platform_fee, 2);

                $wallets = User::query()
                    ->whereIn('id', [$ride->customer_id, $ride->driver_id])
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');
                $customer = $wallets->get($ride->customer_id);
                $driver = $wallets->get($ride->driver_id);

                if (! $customer || ! $driver) {
                    $error = 'تعذر العثور على محفظة الزبون أو السائق.';

                    return;
                }

                if ((float) $driver->wallet_balance < $driverEarning) {
                    $error = 'رصيد السائق لا يغطي استرجاع أرباح الرحلة. سوِّ الرصيد أولًا.';

                    return;
                }

                $customerBalance = round((float) $customer->wallet_balance + $fare, 2);
                $driverBalance = round((float) $driver->wallet_balance - $driverEarning, 2);
                $customer->update(['wallet_balance' => $customerBalance]);
                $driver->update(['wallet_balance' => $driverBalance]);

                WalletTransaction::create([
                    'user_id' => $customer->id,
                    'ride_request_id' => $ride->id,
                    'created_by' => auth()->id(),
                    'type' => 'ride_fare_refund',
                    'amount' => $fare,
                    'balance_after' => $customerBalance,
                    'description' => 'استرجاع أجرة رحلة ملغاة',
                ]);
                WalletTransaction::create([
                    'user_id' => $driver->id,
                    'ride_request_id' => $ride->id,
                    'created_by' => auth()->id(),
                    'type' => 'driver_earning_reversal',
                    'amount' => -$driverEarning,
                    'balance_after' => $driverBalance,
                    'description' => 'سحب أرباح رحلة ملغاة',
                ]);
                WalletTransaction::create([
                    'ride_request_id' => $ride->id,
                    'created_by' => auth()->id(),
                    'type' => 'platform_commission_reversal',
                    'amount' => -round((float) $ride->platform_fee, 2),
                    'description' => 'إلغاء عمولة رحلة ملغاة',
                ]);
            }

            $ride->update([
                'status' => RideStatus::Cancelled->value,
                'actual_fare' => null,
                'platform_fee' => null,
                'commission_percent' => null,
                'completed_at' => null,
            ]);
        });

        if ($error !== null) {
            return back()->withErrors(['status' => $error]);
        }

        $notifications->rideCancelledByAdmin($rideRequest, $driverId);

        return back()->with('status', $wasSettled
            ? 'تم إلغاء الرحلة وإرجاع الأجرة للزبون وسحب الأرباح من السائق.'
            : 'تم إلغاء الرحلة بنجاح.');
    }
}
