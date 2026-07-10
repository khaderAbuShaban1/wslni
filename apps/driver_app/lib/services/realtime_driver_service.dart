part of '../main.dart';

class RealtimeDriverService {
  RealtimeDriverService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  bool get isEnabled => FirebaseRuntime.isReady;

  DatabaseReference get _ridesRef => _database.ref('ride_requests');

  Stream<List<RideRequestItem>> watchOpenRides() {
    if (!isEnabled) return const Stream.empty();

    return _ridesRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <RideRequestItem>[];

      final rides = <RideRequestItem>[];
      for (final raw in value.values) {
        if (raw is! Map) continue;
        final status = raw['status']?.toString() ?? 'open';
        if (status != 'open' && status != 'requested') continue;
        rides.add(
          RideRequestItem(
            id: int.tryParse(raw['id']?.toString() ?? '') ?? 0,
            pickup: raw['pickup_address']?.toString() ?? '',
            dropoff: raw['dropoff_address']?.toString() ?? '',
            customerName: raw['customer_name']?.toString() ?? 'زبون',
            notes: raw['notes']?.toString() ?? '',
            offers: DriverRideOffer.listFrom(raw['offers']),
          ),
        );
      }
      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
  }

  Future<void> sendOffer({
    required RideRequestItem ride,
    required DriverUser driver,
    required String price,
    required String notes,
  }) async {
    if (!isEnabled || ride.id == 0) return;

    await _ridesRef.child('${ride.id}/offers/${driver.id}').set({
      'driver_id': driver.id,
      'driver_name': driver.name,
      'driver_phone': driver.phone,
      'vehicle': driver.vehicleType.isEmpty ? 'سيارة' : driver.vehicleType,
      'vehicle_plate': driver.vehiclePlate,
      'price': price,
      'notes': notes,
      'eta': 'قريبًا',
      'rating': '5.0',
      'created_at': ServerValue.timestamp,
    });
  }
}
