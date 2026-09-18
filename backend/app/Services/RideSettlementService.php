<?php

namespace App\Services;

use App\Enums\RideStatus;
use App\Exceptions\RideSettlementException;
use App\Models\AppSetting;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletTransaction;

/**
 * The one place a ride's money moves on completion, used by the driver app
 * and the admin dashboard alike so the two can never charge differently.
 */
class RideSettlementService
{
    /**
     * Charge the customer, pay the driver, record the wallet transactions and
     * mark the ride completed.
     *
     * Call inside a transaction with the ride row already locked. Every check
     * runs before any write, and a failure throws so the caller's transaction
     * rolls back with nothing half-applied.
     *
     * @throws RideSettlementException
     */
    public function complete(RideRequest $ride, ?int $actorId = null): void
    {
        // Status rules already stop a second completion; this guards the money
        // itself, so no path can ever charge the same ride twice.
        $alreadyCharged = WalletTransaction::query()
            ->where('ride_request_id', $ride->id)
            ->where('type', 'ride_fare_debit')
            ->exists();
        if ($alreadyCharged) {
            throw new RideSettlementException('تمت تسوية هذه الرحلة مسبقًا.');
        }

        $fare = round((float) $ride->actual_fare, 2);
        if ($fare <= 0) {
            throw new RideSettlementException('لا يمكن إنهاء الرحلة قبل تحديد الأجرة.');
        }

        // Locked in id order, the same as every other wallet write, so two
        // settlements touching the same users cannot deadlock.
        $users = User::query()
            ->whereIn('id', [$ride->customer_id, $ride->driver_id])
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');
        $customer = $users->get($ride->customer_id);
        $driver = $users->get($ride->driver_id);
        if (! $customer || ! $driver) {
            throw new RideSettlementException('تعذر العثور على محفظة الزبون أو السائق.');
        }
        if ((float) $customer->wallet_balance < $fare) {
            throw new RideSettlementException('رصيد محفظة الزبون غير كافٍ لإكمال الرحلة.');
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
            'ride_request_id' => $ride->id,
            'created_by' => $actorId,
            'type' => 'ride_fare_debit',
            'amount' => -$fare,
            'balance_after' => $customerBalance,
            'description' => 'خصم أجرة الرحلة',
        ]);
        WalletTransaction::create([
            'user_id' => $driver->id,
            'ride_request_id' => $ride->id,
            'created_by' => $actorId,
            'type' => 'driver_earning_credit',
            'amount' => $driverEarning,
            'balance_after' => $driverBalance,
            'description' => 'صافي أرباح الرحلة',
        ]);
        WalletTransaction::create([
            'ride_request_id' => $ride->id,
            'created_by' => $actorId,
            'type' => 'platform_commission',
            'amount' => $platformFee,
            'description' => 'عمولة التطبيق',
        ]);

        $ride->update([
            'status' => RideStatus::TripCompleted->value,
            'commission_percent' => $commissionPercent,
            'platform_fee' => $platformFee,
            'completed_at' => now(),
        ]);
    }
}
