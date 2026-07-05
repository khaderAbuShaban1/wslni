import '../models/ride_model.dart';
import 'api_client.dart';

class RideService {
  RideService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<RideDraft> createRide({
    required int customerId,
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
      return RideDraft.fromJson(ride);
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
    );
  }
}
