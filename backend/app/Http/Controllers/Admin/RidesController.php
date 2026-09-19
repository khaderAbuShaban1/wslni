<?php

namespace App\Http\Controllers\Admin;

use App\Enums\RideStatus;
use App\Exceptions\RideSettlementException;
use App\Http\Controllers\Controller;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\NotificationDispatcher;
use App\Services\RideSettlementService;
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
            ->with(['customer:id,name,phone,avatar_path', 'driver:id,name,phone,avatar_path'])
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
        RideSettlementService $settlement,
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

        // Nothing is left to do on a cancelled ride. Allowing it again sent the
        // customer a second "ride cancelled" notification.
        if ($currentStatus === RideStatus::Cancelled) {
            return back()->withErrors(['status' => 'هذه الرحلة ملغاة مسبقًا.']);
        }

        // Every stage past receiving offers is about a specific driver. Moving a
        // driverless ride into them told the customer a driver was on the way
        // when none existed.
        $driverStage = ! in_array($requestedStatus, [RideStatus::Pending, RideStatus::ReceivingOffers, RideStatus::Cancelled], true);
        if ($driverStage && $rideRequest->driver_id === null) {
            return back()->withErrors(['status' => 'لا يمكن نقل الرحلة لهذه المرحلة قبل اختيار سائق.']);
        }

        if ($requestedStatus === RideStatus::Cancelled) {
            return $this->cancel($rideRequest, $notifications);
        }

        if ($requestedStatus === RideStatus::TripCompleted) {
            return $this->complete($rideRequest, $data['actual_fare'] ?? null, $settlement);
        }

        // Ordinary stage changes move no money, so they never write a
        // commission; only settlement does. Once a ride is settled its fare is
        // what the customer paid and must stay matching the wallet.
        $settled = in_array($currentStatus, [RideStatus::TripCompleted, RideStatus::Rated], true);

        $rideRequest->fill([
            'status' => $data['status'],
            'actual_fare' => $settled
                ? $rideRequest->actual_fare
                : ($data['actual_fare'] ?? $rideRequest->actual_fare ?? $rideRequest->fare_estimate),
            'distance_km' => $data['distance_km'] ?? $rideRequest->distance_km,
            'accepted_at' => $requestedStatus === RideStatus::DriverConfirmed && $rideRequest->accepted_at === null ? now() : $rideRequest->accepted_at,
        ])->save();

        return back()->with('status', 'تم تحديث الرحلة بنجاح.');
    }

    /**
     * Completing from the dashboard settles exactly as the driver app does,
     * through the same service, so the customer is charged and the driver
     * paid the same way whoever closes the ride.
     */
    private function complete(RideRequest $rideRequest, mixed $postedFare, RideSettlementService $settlement): RedirectResponse
    {
        try {
            DB::transaction(function () use ($rideRequest, $postedFare, $settlement): void {
                $ride = RideRequest::query()->lockForUpdate()->findOrFail($rideRequest->id);

                // The dashboard may correct the agreed fare before charging it.
                $ride->actual_fare = $postedFare ?? $ride->actual_fare ?? $ride->fare_estimate;

                $settlement->complete($ride, auth()->id());
            });
        } catch (RideSettlementException $exception) {
            return back()->withErrors(['status' => $exception->getMessage()]);
        }

        return back()->with('status', 'تم إكمال الرحلة: خُصمت الأجرة من الزبون وأُضيفت أرباح السائق.');
    }

    /**
     * A cancelled ride must leave nobody paid: no fare, no commission, and any
     * money it actually moved is returned to where it came from.
     *
     * What to reverse is read from the ride's recorded wallet transactions,
     * not inferred from its status. A ride marked completed from the dashboard
     * never charged anyone, and refunding it by status handed the customer a
     * fare they never paid.
     */
    private function cancel(RideRequest $rideRequest, NotificationDispatcher $notifications): RedirectResponse
    {
        $driverId = (int) $rideRequest->driver_id;
        $error = null;
        $refunded = false;

        DB::transaction(function () use ($rideRequest, &$error, &$refunded): void {
            $ride = RideRequest::query()->lockForUpdate()->findOrFail($rideRequest->id);

            $moved = WalletTransaction::query()
                ->where('ride_request_id', $ride->id)
                ->lockForUpdate()
                ->get()
                ->groupBy('type');
            $charge = $moved->get('ride_fare_debit')?->first();
            $earning = $moved->get('driver_earning_credit')?->first();
            $commission = $moved->get('platform_commission')?->first();

            if ($charge !== null && ! $moved->has('ride_fare_refund')) {
                $fare = round(abs((float) $charge->amount), 2);
                $driverEarning = round((float) ($earning?->amount ?? 0), 2);
                $customerId = (int) $charge->user_id;
                $earnerId = (int) ($earning?->user_id ?? 0);

                $wallets = User::query()
                    ->whereIn('id', array_filter([$customerId, $earnerId]))
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('id');
                $customer = $wallets->get($customerId);
                $driver = $earnerId > 0 ? $wallets->get($earnerId) : null;

                if (! $customer || ($earnerId > 0 && ! $driver)) {
                    $error = 'تعذر العثور على محفظة الزبون أو السائق.';

                    return;
                }

                if ($driver && (float) $driver->wallet_balance < $driverEarning) {
                    $error = 'رصيد السائق لا يغطي استرجاع أرباح الرحلة. سوِّ الرصيد أولًا.';

                    return;
                }

                $customerBalance = round((float) $customer->wallet_balance + $fare, 2);
                $customer->update(['wallet_balance' => $customerBalance]);
                WalletTransaction::create([
                    'user_id' => $customer->id,
                    'ride_request_id' => $ride->id,
                    'created_by' => auth()->id(),
                    'type' => 'ride_fare_refund',
                    'amount' => $fare,
                    'balance_after' => $customerBalance,
                    'description' => 'استرجاع أجرة رحلة ملغاة',
                ]);

                if ($driver) {
                    $driverBalance = round((float) $driver->wallet_balance - $driverEarning, 2);
                    $driver->update(['wallet_balance' => $driverBalance]);
                    WalletTransaction::create([
                        'user_id' => $driver->id,
                        'ride_request_id' => $ride->id,
                        'created_by' => auth()->id(),
                        'type' => 'driver_earning_reversal',
                        'amount' => -$driverEarning,
                        'balance_after' => $driverBalance,
                        'description' => 'سحب أرباح رحلة ملغاة',
                    ]);
                }

                if ($commission) {
                    WalletTransaction::create([
                        'ride_request_id' => $ride->id,
                        'created_by' => auth()->id(),
                        'type' => 'platform_commission_reversal',
                        'amount' => -round((float) $commission->amount, 2),
                        'description' => 'إلغاء عمولة رحلة ملغاة',
                    ]);
                }

                $refunded = true;
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

        return back()->with('status', $refunded
            ? 'تم إلغاء الرحلة وإرجاع الأجرة للزبون وسحب الأرباح من السائق.'
            : 'تم إلغاء الرحلة بنجاح.');
    }
}
