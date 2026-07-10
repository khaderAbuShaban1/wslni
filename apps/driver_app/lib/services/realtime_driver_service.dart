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
        rides.add(_rideFromRaw(raw));
      }
      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
  }

  Stream<List<RideRequestItem>> watchActiveRides(int driverId) {
    if (!isEnabled) return const Stream.empty();

    return _ridesRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <RideRequestItem>[];

      final rides = <RideRequestItem>[];
      for (final raw in value.values) {
        if (raw is! Map) continue;
        final status = raw['status']?.toString() ?? '';
        final rawDriverId = int.tryParse(raw['driver_id']?.toString() ?? '');
        if (!const {'accepted', 'arrived', 'in_progress'}.contains(status) ||
            rawDriverId != driverId) {
          continue;
        }
        rides.add(_rideFromRaw(raw));
      }
      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
  }

  Stream<List<RideRequestItem>> watchAcceptedRides(int driverId) {
    return watchActiveRides(driverId);
  }

  Future<void> sendOffer({
    required RideRequestItem ride,
    required DriverUser driver,
    required int offerId,
    required String price,
    required String notes,
  }) async {
    if (!isEnabled || ride.id == 0) return;

    await _ridesRef.child('${ride.id}/offers/${driver.id}').set({
      'offer_id': offerId,
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

  Future<void> updateRideStatus({
    required int rideId,
    required String status,
  }) async {
    if (!isEnabled || rideId == 0) return;

    final updates = <String, Object?>{
      'status': status,
      'updated_at': ServerValue.timestamp,
    };
    if (status == 'arrived') updates['arrived_at'] = ServerValue.timestamp;
    if (status == 'in_progress') {
      updates['started_at'] = ServerValue.timestamp;
    }
    if (status == 'completed') {
      updates['completed_at'] = ServerValue.timestamp;
    }
    if (status == 'cancelled') {
      updates['cancelled_at'] = ServerValue.timestamp;
    }

    await _ridesRef.child(rideId.toString()).update(updates);
  }

  Future<void> withdrawOtherOffers({
    required int driverId,
    required int activeRideId,
  }) async {
    if (!isEnabled || driverId == 0) return;

    final snapshot = await _ridesRef.get();
    final value = snapshot.value;
    if (value is! Map) return;

    final updates = <String, Object?>{};
    for (final entry in value.entries) {
      final rideId = int.tryParse(entry.key.toString());
      final rawRide = entry.value;
      if (rideId == null || rideId == activeRideId || rawRide is! Map) {
        continue;
      }
      final offers = rawRide['offers'];
      if (offers is Map && offers.containsKey(driverId.toString())) {
        updates['$rideId/offers/$driverId/status'] = 'rejected';
      }
    }

    if (updates.isNotEmpty) await _ridesRef.update(updates);
  }

  RideRequestItem _rideFromRaw(Map raw) {
    return RideRequestItem(
      id: int.tryParse(raw['id']?.toString() ?? '') ?? 0,
      pickup: raw['pickup_address']?.toString() ?? '',
      dropoff: raw['dropoff_address']?.toString() ?? '',
      customerName: raw['customer_name']?.toString() ?? 'زبون',
      customerPhone: raw['customer_phone']?.toString() ?? '',
      notes: raw['notes']?.toString() ?? '',
      status: raw['status']?.toString() ?? 'requested',
      actualFare: raw['actual_fare']?.toString() ?? '',
      offers: DriverRideOffer.listFrom(raw['offers']),
    );
  }
}
