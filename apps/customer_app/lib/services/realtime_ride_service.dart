import 'package:firebase_database/firebase_database.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../utils/firebase_runtime.dart';

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
      if (value is! Map) return <RideDraft>[];

      final rides = <RideDraft>[];
      for (final raw in value.values) {
        if (raw is! Map) continue;
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
            status: _firebaseStatus(raw['status']?.toString() ?? 'open'),
            offersCount: _countOffers(raw['offers']),
          ),
        );
      }

      rides.sort((a, b) => b.id.compareTo(a.id));
      return rides;
    });
  }

  Stream<List<DriverOffer>> watchOffers(int rideId) {
    if (!isEnabled || rideId == 0) return const Stream.empty();

    return _ridesRef.child('$rideId/offers').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <DriverOffer>[];

      final offers = <DriverOffer>[];
      for (final raw in value.values) {
        if (raw is! Map) continue;
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
      'status': 'accepted',
      'driver_id': offer.driverId,
      'accepted_offer_id': offer.id,
      'accepted_at': ServerValue.timestamp,
    });
    await _ridesRef.child('${ride.id}/offers/${offer.driverId}').update({
      'status': 'accepted',
    });
  }

  int _countOffers(Object? value) {
    if (value is Map) return value.length;
    if (value is List) return value.length;
    return 0;
  }

  String _firebaseStatus(String status) {
    return switch (status) {
      'requested' => 'open',
      _ => status,
    };
  }
}
