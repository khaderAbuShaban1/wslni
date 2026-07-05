import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) {
    return _api.post('auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post('auth/login', {
      'email': email,
      'password': password,
    });
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<AppUser> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _api.post('auth/verify-otp', {
      'email': email,
      'otp': otp,
    });
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<void> resendOtp(String email) {
    return _api.post('auth/resend-otp', {'email': email}).then((_) {});
  }
}
