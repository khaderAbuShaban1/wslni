import 'package:flutter/material.dart';

// Premium "Obsidian Gold" identity tokens. Legacy names remain in place to
// avoid touching application behavior while every visual consumer adopts the
// new palette.
const emerald = Color(0xFFE9B934);
const darkText = Color(0xFF111214);
const mutedText = Color(0xFF747880);
const lightGray = Color(0xFFF4F4F6);
const borderGray = Color(0xFFE5E5E8);
const successColor = Color(0xFF20835B);
const warningColor = Color(0xFFD99C18);
const errorColor = Color(0xFFC73A31);
const infoColor = Color(0xFF30343A);

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
}
