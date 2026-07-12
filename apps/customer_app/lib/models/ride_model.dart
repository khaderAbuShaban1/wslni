import '../utils/constants.dart';

class RideDraft {
  const RideDraft({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.rideName,
    required this.price,
    required this.eta,
    this.status = 'open',
    this.offersCount = 0,
    this.customerId = 0,
    this.driverName = '',
    this.driverPhone = '',
    this.driverCar = '',
    this.driverPlate = '',
  });

  final int id;
  final String pickup;
  final String destination;
  final String rideName;
  final String price;
  final String eta;
  final String status;
  final int offersCount;
  final int customerId;
  final String driverName;
  final String driverPhone;
  final String driverCar;
  final String driverPlate;

  factory RideDraft.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    final driverMap = driver is Map ? driver : const {};
    final profile = driverMap['driver_profile'];
    final profileMap = profile is Map ? profile : const {};
    return RideDraft(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pickup: json['pickup_address']?.toString() ?? '',
      destination: json['dropoff_address']?.toString() ?? '',
      rideName: 'طلب جديد',
      price: 'بانتظار العرض',
      eta: 'بانتظار السائق',
      status: RideStatuses.normalize(
        json['status']?.toString() ?? RideStatuses.pending,
      ),
      offersCount: _offersCount(json['offers']),
      customerId: int.tryParse(json['customer_id']?.toString() ?? '') ?? 0,
      driverName: driverMap['name']?.toString() ?? '',
      driverPhone: driverMap['phone']?.toString() ?? '',
      driverCar: profileMap['vehicle_type']?.toString() ?? '',
      driverPlate: profileMap['vehicle_plate']?.toString() ?? '',
    );
  }

  String get statusLabel {
    return switch (status) {
      RideStatuses.pending => 'جاري إرسال الطلب للسائقين',
      RideStatuses.receivingOffers => 'يتم استقبال عروض السائقين',
      RideStatuses.driverSelected => 'بانتظار تأكيد السائق',
      RideStatuses.driverConfirmed => 'تم تأكيد الرحلة',
      RideStatuses.driverOnTheWay => 'السائق في الطريق',
      RideStatuses.driverArrived => 'وصل السائق إليك',
      RideStatuses.tripStarted => 'الرحلة قيد التنفيذ',
      RideStatuses.tripCompleted => 'مكتملة',
      RideStatuses.rated => 'مكتملة ومقيّمة',
      RideStatuses.cancelled => 'ملغية',
      _ => 'بانتظار العروض',
    };
  }

  static int _offersCount(Object? value) {
    if (value is Map) return value.length;
    if (value is List) return value.length;
    return 0;
  }
}
