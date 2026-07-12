part of '../main.dart';

class RealtimeDriverService {
  RealtimeDriverService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  bool get isEnabled => FirebaseRuntime.isReady;

  DatabaseReference get _ridesRef => _database.ref('ride_requests');

  Stream<List<Map<String, dynamic>>> watchWithdrawals(int driverId) {
    if (!isEnabled || driverId == 0) return const Stream.empty();
    return _database.ref('driver_withdrawals/$driverId').onValue.map((event) {
      final rows = <Map<String, dynamic>>[];
      for (final raw in _rows(event.snapshot.value)) {
        rows.add(Map<String, dynamic>.from(raw));
      }
      rows.sort(
        (a, b) => (int.tryParse(b['id']?.toString() ?? '') ?? 0).compareTo(
          int.tryParse(a['id']?.toString() ?? '') ?? 0,
        ),
      );
      return rows;
    });
  }

  Stream<List<RideRequestItem>> watchOpenRides() {
    if (!isEnabled) return const Stream.empty();

    return _ridesRef.onValue.map((event) {
      final value = event.snapshot.value;

      final rides = <RideRequestItem>[];
      for (final raw in _rows(value)) {
        final status = RideStatuses.normalize(
          raw['status']?.toString() ?? RideStatuses.pending,
        );
        if (!RideStatuses.openForOffers.contains(status)) continue;
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

      final rides = <RideRequestItem>[];
      for (final raw in _rows(value)) {
        final status = RideStatuses.normalize(raw['status']?.toString() ?? '');
        final rawDriverId = int.tryParse(raw['driver_id']?.toString() ?? '');
        if (!RideStatuses.activeForDriver.contains(status) ||
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

  Stream<List<RideRequestItem>> watchDriverRides(int driverId) {
    if (!isEnabled) return const Stream.empty();

    return _ridesRef.onValue.map((event) {
      final value = event.snapshot.value;
      final rides = <RideRequestItem>[];
      for (final raw in _rows(value)) {
        final rawDriverId = int.tryParse(raw['driver_id']?.toString() ?? '');
        if (rawDriverId == driverId) rides.add(_rideFromRaw(raw));
      }
      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
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
    await _ridesRef.child('${ride.id}/status').runTransaction((value) {
      if (value == RideStatuses.pending) {
        return Transaction.success(RideStatuses.receivingOffers);
      }
      return Transaction.abort();
    });
  }

  Future<void> updateRideStatus({
    required int rideId,
    required String status,
    String? actualFare,
    String? platformFee,
  }) async {
    if (!isEnabled || rideId == 0) return;

    final updates = <String, Object?>{
      'status': status,
      'updated_at': ServerValue.timestamp,
    };
    if (status == RideStatuses.driverArrived) {
      updates['arrived_at'] = ServerValue.timestamp;
    }
    if (status == RideStatuses.tripStarted) {
      updates['started_at'] = ServerValue.timestamp;
    }
    if (status == RideStatuses.tripCompleted) {
      updates['completed_at'] = ServerValue.timestamp;
      if (actualFare != null) updates['actual_fare'] = actualFare;
      if (platformFee != null) updates['platform_fee'] = platformFee;
    }
    if (status == RideStatuses.cancelled) {
      updates['cancelled_at'] = ServerValue.timestamp;
    }

    await _ridesRef.child(rideId.toString()).update(updates);
  }

  Future<void> respondToSelection({
    required int rideId,
    required int driverId,
    required bool accepted,
  }) async {
    if (!isEnabled || rideId == 0 || driverId == 0) return;

    final updates = <String, Object?>{
      'status': accepted
          ? RideStatuses.driverConfirmed
          : RideStatuses.receivingOffers,
      'updated_at': ServerValue.timestamp,
      'offers/$driverId/status': accepted ? 'accepted' : 'rejected',
    };
    if (accepted) {
      updates['confirmed_at'] = ServerValue.timestamp;
    } else {
      updates['driver_id'] = null;
      final snapshot = await _ridesRef.child('$rideId/offers').get();
      final offers = snapshot.value;
      if (offers is Map) {
        for (final key in offers.keys) {
          if (key.toString() != driverId.toString()) {
            updates['offers/${key.toString()}/status'] = 'pending';
          }
        }
      }
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

    final updates = <String, Object?>{};
    for (final entry in _indexedRows(value)) {
      final rideId = entry.$1;
      final rawRide = entry.$2;
      if (rideId == activeRideId) {
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
      status: RideStatuses.normalize(
        raw['status']?.toString() ?? RideStatuses.pending,
      ),
      actualFare: raw['actual_fare']?.toString() ?? '',
      platformFee: raw['platform_fee']?.toString() ?? '',
      offers: DriverRideOffer.listFrom(raw['offers']),
    );
  }

  Iterable<Map> _rows(Object? value) sync* {
    if (value is Map) {
      for (final row in value.values) {
        if (row is Map) yield row;
      }
    } else if (value is List) {
      for (final row in value) {
        if (row is Map) yield row;
      }
    }
  }

  Iterable<(int, Map)> _indexedRows(Object? value) sync* {
    if (value is Map) {
      for (final entry in value.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id != null && entry.value is Map) yield (id, entry.value as Map);
      }
    } else if (value is List) {
      for (var index = 0; index < value.length; index++) {
        final row = value[index];
        if (row is Map) yield (index, row);
      }
    }
  }
}
