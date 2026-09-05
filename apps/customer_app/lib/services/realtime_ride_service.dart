import 'package:firebase_database/firebase_database.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../utils/firebase_runtime.dart';
import '../utils/constants.dart';

class RealtimeRideService {
  RealtimeRideService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  bool get isEnabled => FirebaseRuntime.isReady;

  DatabaseReference get _ridesRef => _database.ref('ride_requests');

  Future<void> publishRide({
    required RideDraft ride,
    required int customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    // Laravel/MySQL is authoritative. The backend mirrors the saved ride to
    // Firebase after it commits, preventing clients from creating stale rows.
    return;
  }

  Stream<List<RideDraft>> watchCustomerRides(int customerId) {
    if (!isEnabled) return const Stream.empty();

    return _database.ref('users/$customerId/rides').onValue.map((event) {
      final value = event.snapshot.value;

      final rides = <RideDraft>[];
      for (final raw in _rows(value)) {
        final rawCustomerId = int.tryParse(
          raw['customer_id']?.toString() ?? '',
        );
        if (rawCustomerId != customerId) continue;
        rides.add(
          RideDraft(
            id: int.tryParse(raw['id']?.toString() ?? '') ?? 0,
            pickup: raw['pickup_address']?.toString() ?? '',
            destination: raw['dropoff_address']?.toString() ?? '',
            rideName: 'طلب رحلة',
            price: raw['actual_fare']?.toString() ?? 'بانتظار العرض',
            eta: 'بانتظار السائق',
            status: RideStatuses.normalize(
              raw['status']?.toString() ?? RideStatuses.pending,
            ),
            offersCount: _countOffers(raw['offers']),
            customerId: rawCustomerId ?? 0,
            driverName: raw['driver_name']?.toString() ?? '',
            driverPhone: raw['driver_phone']?.toString() ?? '',
            driverCar: raw['vehicle']?.toString() ?? '',
            driverPlate: raw['vehicle_plate']?.toString() ?? '',
          ),
        );
      }

      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
  }

  Stream<RideDraft?> watchRide(int customerId, int rideId) {
    if (!isEnabled || customerId == 0 || rideId == 0) {
      return Stream.value(null);
    }

    return _database.ref('users/$customerId/rides/$rideId').onValue.map((
      event,
    ) {
      final raw = event.snapshot.value;
      if (raw is! Map) return null;
      return _rideFromRealtime(raw);
    });
  }

  RideDraft _rideFromRealtime(Map raw) {
    return RideDraft(
      id: int.tryParse(raw['id']?.toString() ?? '') ?? 0,
      pickup: raw['pickup_address']?.toString() ?? '',
      destination: raw['dropoff_address']?.toString() ?? '',
      rideName: 'طلب رحلة',
      price: raw['actual_fare']?.toString() ?? 'بانتظار العرض',
      eta: raw['eta']?.toString() ?? 'بانتظار السائق',
      status: RideStatuses.normalize(
        raw['status']?.toString() ?? RideStatuses.pending,
      ),
      offersCount: _countOffers(raw['offers']),
      customerId: int.tryParse(raw['customer_id']?.toString() ?? '') ?? 0,
      driverName: raw['driver_name']?.toString() ?? '',
      driverPhone: raw['driver_phone']?.toString() ?? '',
      driverCar: raw['vehicle']?.toString() ?? '',
      driverPlate: raw['vehicle_plate']?.toString() ?? '',
    );
  }

  Stream<List<DriverOffer>> watchOffers(int customerId, int rideId) {
    if (!isEnabled || customerId == 0 || rideId == 0) {
      return const Stream.empty();
    }

    return _database.ref('users/$customerId/rides/$rideId/offers').onValue.map((
      event,
    ) {
      final value = event.snapshot.value;

      final offers = <DriverOffer>[];
      for (final raw in _rows(value)) {
        final status = raw['status']?.toString() ?? 'pending';
        if (status == 'rejected' || status == 'cancelled') continue;
        offers.add(
          DriverOffer(
            id:
                int.tryParse(
                  raw['offer_id']?.toString() ?? raw['id']?.toString() ?? '',
                ) ??
                0,
            driverId: int.tryParse(raw['driver_id']?.toString() ?? '') ?? 0,
            name: raw['driver_name']?.toString() ?? 'سائق',
            rating: raw['rating']?.toString() ?? '5.0',
            car: raw['vehicle']?.toString() ?? 'سيارة',
            price: '${raw['price']?.toString() ?? '0'} شيكل',
            eta: raw['eta']?.toString() ?? 'قريبًا',
            phone: raw['driver_phone']?.toString() ?? '',
            vehiclePlate: raw['vehicle_plate']?.toString() ?? '',
          ),
        );
      }
      return offers;
    });
  }

  Future<void> acceptOffer({
    required RideDraft ride,
    required DriverOffer offer,
  }) async {
    // The API accepts the offer and the backend publishes the canonical state.
    return;
  }

  Future<void> markRated(int rideId, int rating, String comment) async {
    // Rating is persisted by the API and mirrored by the backend.
    return;
  }

  int _countOffers(Object? value) {
    if (value is Map) return value.length;
    if (value is List) return value.length;
    return 0;
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

  String _firebaseStatus(String status) => status;
}
