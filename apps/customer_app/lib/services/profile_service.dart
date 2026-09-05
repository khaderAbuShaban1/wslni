import '../models/user_model.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async {
    final result = await _api.patch('customers/me', {
      'name': name,
      'phone': phone,
    });
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }
}
