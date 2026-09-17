<?php

namespace App\Services;

use App\Models\DriverProfile;
use App\Models\DriverWithdrawal;
use App\Models\RideOffer;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\WalletDeposit;
use Illuminate\Database\Eloquent\Model;

class NotificationDispatcher
{
    public function __construct(private FcmService $fcm) {}

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
            // Cancellation is announced by the controller that performed it.
            // Who cancelled cannot be read off the model, and guessing it from
            // driver_id told customers the driver had cancelled when it was an
            // admin, and reached nobody at all when it was the customer.
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

    /**
     * Customer cancelled. The controller clears driver_id in the same update
     * that sets the status, so the driver must be passed in.
     */
    public function rideCancelledByCustomer(RideRequest $ride, int $driverId): void
    {
        if ($driverId <= 0) {
            return;
        }

        $this->notify(
            $driverId,
            'ألغى الزبون الرحلة ❌',
            'ألغى الزبون هذه الرحلة. يمكنك استقبال طلبات جديدة الآن.',
            $this->cancellationData($ride),
        );
    }

    /** Driver cancelled: only the customer needs telling. */
    public function rideCancelledByDriver(RideRequest $ride): void
    {
        $this->notify(
            $ride->customer_id,
            'تم إلغاء الرحلة ❌',
            'ألغى السائق الرحلة. يمكنك طلب رحلة جديدة الآن.',
            $this->cancellationData($ride),
        );
    }

    /** Admin cancelled: neither side chose this, so both are told. */
    public function rideCancelledByAdmin(RideRequest $ride, int $driverId): void
    {
        $this->notify(
            $ride->customer_id,
            'تم إلغاء الرحلة ❌',
            'ألغت الإدارة هذه الرحلة. تواصل مع الدعم لمزيد من التفاصيل.',
            $this->cancellationData($ride),
        );

        if ($driverId > 0) {
            $this->notify(
                $driverId,
                'تم إلغاء الرحلة ❌',
                'ألغت الإدارة هذه الرحلة. يمكنك استقبال طلبات جديدة الآن.',
                $this->cancellationData($ride),
            );
        }
    }

    /** @return array<string, string> */
    private function cancellationData(RideRequest $ride): array
    {
        return ['type' => 'ride_status', 'ride_id' => (string) $ride->id, 'status' => 'cancelled'];
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
        if ($deposit->wasRecentlyCreated && $deposit->status === 'pending') {
            $this->notify(
                $deposit->user_id,
                'تم استلام طلب الإيداع 📩',
                "تم استلام طلب إيداعك بمبلغ {$deposit->amount} شيكل وسيتم مراجعته من الإدارة.",
                ['type' => 'wallet', 'action' => 'deposit_pending', 'deposit_id' => (string) $deposit->id],
            );
            return;
        }

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
        $user = User::find($userId);
        if ($user && $user->fcm_token) {
            $this->fcm->sendToUser($user, $title, $body, $data);
        }
    }
}
