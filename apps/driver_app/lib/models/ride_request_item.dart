part of '../main.dart';

class RideRequestItem {
  RideRequestItem({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.customerName,
    required this.notes,
    this.customerPhone = '',
    this.status = RideStatuses.pending,
    this.actualFare = '',
    this.platformFee = '',
    this.offers = const [],
  });

  final int id;
  final String pickup;
  final String dropoff;
  final String customerName;
  final String customerPhone;
  final String notes;
  final String status;
  final String actualFare;
  final String platformFee;
  final List<DriverRideOffer> offers;

  bool get isActive => RideStatuses.activeForDriver.contains(status);

  String get statusLabel {
    return switch (status) {
      RideStatuses.driverSelected => 'بانتظار تأكيدك',
      RideStatuses.driverConfirmed => 'تم تأكيد الرحلة',
      RideStatuses.driverOnTheWay => 'في الطريق إلى الزبون',
      RideStatuses.driverArrived => 'وصلت إلى الزبون',
      RideStatuses.tripStarted => 'الرحلة قيد التنفيذ',
      RideStatuses.tripCompleted => 'رحلة مكتملة',
      RideStatuses.cancelled => 'رحلة ملغاة',
      _ => 'بانتظار القبول',
    };
  }

  int? get lowestOffer {
    final prices = offers
        .map((offer) => int.tryParse(offer.price))
        .whereType<int>()
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  factory RideRequestItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final customerMap = customer is Map ? customer : {};
    return RideRequestItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pickup: json['pickup_address']?.toString() ?? '',
      dropoff: json['dropoff_address']?.toString() ?? '',
      customerName: customerMap['name']?.toString() ?? 'زبون',
      customerPhone: customerMap['phone']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? RideStatuses.pending,
      actualFare: json['actual_fare']?.toString() ?? '',
      platformFee: json['platform_fee']?.toString() ?? '',
      offers: DriverRideOffer.listFrom(json['offers']),
    );
  }
}

class DriverRideOffer {
  const DriverRideOffer({
    required this.driverId,
    required this.driverName,
    required this.price,
    required this.vehicle,
  });

  final int driverId;
  final String driverName;
  final String price;
  final String vehicle;

  factory DriverRideOffer.fromMap(Map map) {
    final driver = map['driver'];
    final driverMap = driver is Map ? driver : const {};
    final profile = driverMap['driver_profile'];
    final profileMap = profile is Map ? profile : const {};
    final realtimeVehicle = map['vehicle']?.toString().trim() ?? '';
    final profileVehicle = profileMap['vehicle_type']?.toString().trim() ?? '';

    return DriverRideOffer(
      driverId: int.tryParse(map['driver_id']?.toString() ?? '') ?? 0,
      driverName:
          map['driver_name']?.toString() ??
          driverMap['name']?.toString() ??
          'سائق',
      price: map['price']?.toString() ?? '0',
      vehicle: realtimeVehicle.isNotEmpty
          ? realtimeVehicle
          : profileVehicle.isNotEmpty
          ? profileVehicle
          : 'سيارة',
    );
  }

  static List<DriverRideOffer> listFrom(Object? value) {
    if (value is Map) {
      return value.values
          .whereType<Map>()
          .map(DriverRideOffer.fromMap)
          .toList();
    }
    if (value is List) {
      return value.whereType<Map>().map(DriverRideOffer.fromMap).toList();
    }
    return const [];
  }
}
