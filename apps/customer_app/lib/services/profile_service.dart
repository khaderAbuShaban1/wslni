import '../models/user_model.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String phone,
  }) async {
    final result = await _api.patch('customers/$userId', {
      'name': name,
      'phone': phone,
    });
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }
}
