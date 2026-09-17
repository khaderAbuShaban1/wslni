<?php

namespace App\Enums;

enum RideStatus: string
{
    case Pending = 'pending';
    case ReceivingOffers = 'receiving_offers';
    case DriverSelected = 'driver_selected';
    case DriverConfirmed = 'driver_confirmed';
    case DriverOnTheWay = 'driver_on_the_way';
    case DriverArrived = 'driver_arrived';
    case TripStarted = 'trip_started';
    case TripCompleted = 'trip_completed';
    case Rated = 'rated';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'معلقة',
            self::ReceivingOffers => 'تستقبل عروض',
            self::DriverSelected => 'تم اختيار سائق',
            self::DriverConfirmed => 'مؤكدة',
            self::DriverOnTheWay => 'السائق في الطريق',
            self::DriverArrived => 'وصل السائق',
            self::TripStarted => 'قيد التنفيذ',
            self::TripCompleted => 'مكتملة',
            self::Rated => 'مقيّمة',
            self::Cancelled => 'ملغاة',
        };
    }

    /** @return array<string, string> value => Arabic label */
    public static function labels(): array
    {
        return array_column(
            array_map(fn (self $case) => ['value' => $case->value, 'label' => $case->label()], self::cases()),
            'label',
            'value',
        );
    }

    public static function labelFor(?string $value): string
    {
        return self::tryFrom((string) $value)?->label() ?? (string) $value;
    }

    public function next(): ?self
    {
        return match ($this) {
            self::Pending => self::ReceivingOffers,
            self::ReceivingOffers => self::DriverSelected,
            self::DriverSelected => self::DriverConfirmed,
            self::DriverConfirmed => self::DriverOnTheWay,
            self::DriverOnTheWay => self::DriverArrived,
            self::DriverArrived => self::TripStarted,
            self::TripStarted => self::TripCompleted,
            self::TripCompleted => self::Rated,
            default => null,
        };
    }

    public static function activeValues(): array
    {
        return [
            self::DriverSelected->value,
            self::DriverConfirmed->value,
            self::DriverOnTheWay->value,
            self::DriverArrived->value,
            self::TripStarted->value,
        ];
    }
}
