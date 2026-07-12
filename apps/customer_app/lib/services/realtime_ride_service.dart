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
    if (!isEnabled || ride.id == 0) return;

    await _ridesRef.child(ride.id.toString()).set({
      'id': ride.id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup_address': ride.pickup,
      'dropoff_address': ride.destination,
      'status': _firebaseStatus(ride.status),
      'created_at': ServerValue.timestamp,
    });
  }

  Stream<List<RideDraft>> watchCustomerRides(int customerId) {
    if (!isEnabled) return const Stream.empty();

    return _ridesRef.onValue.map((event) {
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
            price: 'بانتظار العرض',
            eta: 'بانتظار السائق',
            status: raw['status']?.toString() ?? RideStatuses.pending,
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

  Stream<RideDraft?> watchRide(int rideId) {
    if (!isEnabled || rideId == 0) return Stream.value(null);

    return _ridesRef.child(rideId.toString()).onValue.map((event) {
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
      status: raw['status']?.toString() ?? RideStatuses.pending,
      offersCount: _countOffers(raw['offers']),
      customerId: int.tryParse(raw['customer_id']?.toString() ?? '') ?? 0,
      driverName: raw['driver_name']?.toString() ?? '',
      driverPhone: raw['driver_phone']?.toString() ?? '',
      driverCar: raw['vehicle']?.toString() ?? '',
      driverPlate: raw['vehicle_plate']?.toString() ?? '',
    );
  }

  Stream<List<DriverOffer>> watchOffers(int rideId) {
    if (!isEnabled || rideId == 0) return const Stream.empty();

    return _ridesRef.child('$rideId/offers').onValue.map((event) {
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
    if (!isEnabled || ride.id == 0 || offer.driverId == 0) return;

    await _ridesRef.child(ride.id.toString()).update({
      'status': RideStatuses.driverSelected,
      'driver_id': offer.driverId,
      'driver_name': offer.name,
      'driver_phone': offer.phone,
      'vehicle': offer.car,
      'vehicle_plate': offer.vehiclePlate,
      'accepted_offer_id': offer.id,
      'accepted_at': ServerValue.timestamp,
    });
    await _ridesRef.child('${ride.id}/offers/${offer.driverId}').update({
      'status': 'selected',
    });

    final snapshot = await _ridesRef.child('${ride.id}/offers').get();
    final offers = snapshot.value;
    if (offers is Map) {
      final updates = <String, Object?>{};
      for (final key in offers.keys) {
        if (key.toString() != offer.driverId.toString()) {
          updates['${key.toString()}/status'] = 'inactive';
        }
      }
      if (updates.isNotEmpty) {
        await _ridesRef.child('${ride.id}/offers').update(updates);
      }
    } else if (offers is List) {
      final updates = <String, Object?>{};
      for (var index = 0; index < offers.length; index++) {
        if (offers[index] is Map && index != offer.driverId) {
          updates['$index/status'] = 'inactive';
        }
      }
      if (updates.isNotEmpty) {
        await _ridesRef.child('${ride.id}/offers').update(updates);
      }
    }
  }

  Future<void> markRated(int rideId, int rating, String comment) async {
    if (!isEnabled || rideId == 0) return;
    await _ridesRef.child(rideId.toString()).update({
      'status': RideStatuses.rated,
      'rating': rating,
      'rating_comment': comment,
      'rated_at': ServerValue.timestamp,
    });
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
