<?php

namespace App\Services;

use App\Jobs\SendFcmNotification;
use App\Models\DriverProfile;
use App\Models\DriverWithdrawal;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\WalletDeposit;
use Illuminate\Database\Eloquent\Model;

class NotificationDispatcher
{
    /**
     * Dispatch push notifications based on model changes.
     * Called from the observer after each saved event.
     */
    public function dispatch(Model $model): void
    {
        match (true) {
            $model instanceof RideRequest => $this->handleRide($model),
            $model instanceof RideOffer => $this->handleOffer($model),
            $model instanceof WalletDeposit => $this->handleDeposit($model),
            $model instanceof DriverWithdrawal => $this->handleWithdrawal($model),
            $model instanceof DriverProfile => $this->handleDriverProfile($model),
            default => null,
        };
    }

    private function handleRide(RideRequest $ride): void
    {
        $status = $ride->status;
        $changed = $ride->wasChanged('status');

        if (! $changed) return;

        match ($status) {
            // Customer receives notification when ride status changes.
            'driver_confirmed' => $this->notify(
                $ride->customer_id,
                'تم تأكيد الرحلة ✅',
                'السائق أكّد الرحلة وسيكون في طريقه إليك قريبًا.',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => $status],
            ),
            'driver_on_the_way' => $this->notify(
                $ride->customer_id,
                'السائق في الطريق 🚗',
                'السائق في طريقه إلى موقع الانطلاق.',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => $status],
            ),
            'driver_arrived' => $this->notify(
                $ride->customer_id,
                'السائق وصل 📍',
                'السائق وصل إلى نقطة الانطلاق.',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => $status],
            ),
            'trip_started' => $this->notify(
                $ride->customer_id,
                'بدأت الرحلة 🛣️',
                'رحلتك بدأت. نتمنى لك رحلة آمنة!',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => $status],
            ),
            'trip_completed' => $this->notify(
                $ride->customer_id,
                'اكتملت الرحلة 🎉',
                'تمت الرحلة بنجاح. شكرًا لاستخدامك وصّلني!',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => $status],
            ),
            'driver_selected' => $this->notifyDriverSelected($ride),
            'receiving_offers' => $this->notifyReceivingOffers($ride),
            'cancelled' => $this->notifyCancellation($ride),
            default => null,
        };
    }

    private function notifyDriverSelected(RideRequest $ride): void
    {
        if (! $ride->driver_id) return;

        $this->notify(
            $ride->driver_id,
            'تم اختيارك! 🎯',
            'زبون اختارك لرحلته. أكّد قبول الرحلة الآن.',
            ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => 'driver_selected'],
        );
    }

    private function notifyReceivingOffers(RideRequest $ride): void
    {
        // If the ride went back to receiving_offers (driver rejected), notify the customer.
        if ($ride->wasChanged('driver_id') && $ride->driver_id === null) {
            $this->notify(
                $ride->customer_id,
                'السائق اعتذر 🔄',
                'السائق المحدد اعتذر عن الرحلة. يمكنك اختيار سائق آخر.',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => 'receiving_offers'],
            );
        }
    }

    private function notifyCancellation(RideRequest $ride): void
    {
        // Notify the other party about the cancellation.
        if ($ride->driver_id) {
            $this->notify(
                $ride->customer_id,
                'تم إلغاء الرحلة ❌',
                'السائق ألغى الرحلة.',
                ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => 'cancelled'],
            );
        }
    }

    private function handleOffer(RideOffer $offer): void
    {
        if (! $offer->wasChanged('status') && ! $offer->wasRecentlyCreated) return;

        $ride = RideRequest::find($offer->ride_request_id);
        if (! $ride) return;

        if ($offer->wasRecentlyCreated || ($offer->wasChanged('status') && $offer->status === 'pending')) {
            $driver = \App\Models\User::find($offer->driver_id);
            $driverName = $driver?->name ?? 'سائق';

            $this->notify(
                $ride->customer_id,
                'عرض سعر جديد 💰',
                "{$driverName} قدّم عرض بسعر {$offer->price} شيكل.",
                ['type' => 'new_offer', 'ride_id' => (string) $ride->id, 'offer_id' => (string) $offer->id],
            );
        }
    }

    private function handleDeposit(WalletDeposit $deposit): void
    {
        if (! $deposit->wasChanged('status')) return;

        match ($deposit->status) {
            'approved' => $this->notify(
                $deposit->user_id,
                'تم شحن المحفظة ✅',
                "تمت الموافقة على إيداعك بمبلغ {$deposit->amount} شيكل.",
                ['type' => 'wallet', 'action' => 'deposit_approved', 'deposit_id' => (string) $deposit->id],
            ),
            'rejected' => $this->notify(
                $deposit->user_id,
                'تم رفض الإيداع ❌',
                "تم رفض طلب الإيداع بمبلغ {$deposit->amount} شيكل.",
                ['type' => 'wallet', 'action' => 'deposit_rejected', 'deposit_id' => (string) $deposit->id],
            ),
            default => null,
        };
    }

    private function handleWithdrawal(DriverWithdrawal $withdrawal): void
    {
        if (! $withdrawal->wasChanged('status')) return;

        match ($withdrawal->status) {
            'paid' => $this->notify(
                $withdrawal->driver_id,
                'تم تحويل السحب ✅',
                "تم تحويل مبلغ {$withdrawal->amount} شيكل إلى حسابك.",
                ['type' => 'wallet', 'action' => 'withdrawal_paid', 'withdrawal_id' => (string) $withdrawal->id],
            ),
            'rejected' => $this->notify(
                $withdrawal->driver_id,
                'تم رفض طلب السحب ❌',
                "تم رفض طلب السحب وأُعيد المبلغ {$withdrawal->amount} شيكل إلى محفظتك.",
                ['type' => 'wallet', 'action' => 'withdrawal_rejected', 'withdrawal_id' => (string) $withdrawal->id],
            ),
            default => null,
        };
    }

    private function handleDriverProfile(DriverProfile $profile): void
    {
        if (! $profile->wasChanged('approval_status')) return;

        match ($profile->approval_status) {
            'approved' => $this->notify(
                $profile->user_id,
                'تمت الموافقة على حسابك! 🎉',
                'تم اعتماد حسابك كسائق. يمكنك البدء بقبول الرحلات الآن.',
                ['type' => 'driver_approval', 'status' => 'approved'],
            ),
            'rejected' => $this->notify(
                $profile->user_id,
                'تم رفض طلب السائق ❌',
                $profile->rejection_reason ?: 'تم رفض طلبك. تواصل مع الدعم لمزيد من التفاصيل.',
                ['type' => 'driver_approval', 'status' => 'rejected'],
            ),
            default => null,
        };
    }

    private function notify(int $userId, string $title, string $body, array $data = []): void
    {
        SendFcmNotification::dispatch($userId, $title, $body, $data);
    }
}
