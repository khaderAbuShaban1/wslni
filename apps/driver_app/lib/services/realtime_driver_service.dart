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
    // Offers are saved in MySQL by the API, then mirrored by Laravel.
    return;
  }

  Future<void> updateRideStatus({
    required int rideId,
    required String status,
    String? actualFare,
    String? platformFee,
  }) async {
    // Status updates are committed by Laravel before Firebase is updated.
    return;
  }

  Future<void> respondToSelection({
    required int rideId,
    required int driverId,
    required bool accepted,
  }) async {
    // Confirmation is committed by the API and mirrored by Laravel.
    return;
  }

  Future<void> withdrawOtherOffers({
    required int driverId,
    required int activeRideId,
  }) async {
    // Laravel enforces one active ride and publishes the resulting offer state.
    return;
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
