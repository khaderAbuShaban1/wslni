import '../models/ride_model.dart';
import 'api_client.dart';
import 'realtime_ride_service.dart';

class RideService {
  RideService({ApiClient? api, RealtimeRideService? realtime})
    : _api = api ?? ApiClient(),
      _realtime = realtime ?? RealtimeRideService();

  final ApiClient _api;
  final RealtimeRideService _realtime;

  Future<List<RideDraft>> listCustomerRides(int customerId) async {
    final rows = await _api.getList('rides?customer_id=$customerId');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(RideDraft.fromJson)
        .toList();
  }

  Future<RideDraft> createRide({
    required int customerId,
    required String customerName,
    required String pickup,
    required String destination,
  }) async {
    final result = await _api.post('rides', {
      'customer_id': customerId,
      'pickup_address': pickup,
      'dropoff_address': destination,
    });
    final ride = result['ride'];
    if (ride is Map<String, dynamic>) {
      final draft = RideDraft.fromJson(ride);
      await _realtime.publishRide(
        ride: draft,
        customerId: customerId,
        customerName: customerName,
      );
      return draft;
    }
    return createDraft(pickup: pickup, destination: destination);
  }

  RideDraft createDraft({required String pickup, required String destination}) {
    return RideDraft(
      id: 0,
      pickup: pickup,
      destination: destination,
      rideName: 'طلب جديد',
      price: 'بانتظار العرض',
      eta: 'بانتظار السائق',
      status: 'open',
    );
  }
}
