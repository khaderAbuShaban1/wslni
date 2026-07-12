part of '../main.dart';

const _emerald = Color(0xFFE9B934);
const _dark = Color(0xFF111214);
const _muted = Color(0xFF747880);
const _line = Color(0xFFE5E5E8);
const _success = Color(0xFF20835B);
const _error = Color(0xFFC73A31);

abstract final class RideStatuses {
  static const pending = 'pending';
  static const receivingOffers = 'receiving_offers';
  static const driverSelected = 'driver_selected';
  static const driverConfirmed = 'driver_confirmed';
  static const driverOnTheWay = 'driver_on_the_way';
  static const driverArrived = 'driver_arrived';
  static const tripStarted = 'trip_started';
  static const tripCompleted = 'trip_completed';
  static const rated = 'rated';
  static const cancelled = 'cancelled';

  static const openForOffers = {pending, receivingOffers};
  static const activeForDriver = {
    driverSelected,
    driverConfirmed,
    driverOnTheWay,
    driverArrived,
    tripStarted,
  };
}
