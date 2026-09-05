import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/firebase_runtime.dart';
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
    return _authenticatedUser(result);
  }

  Future<AppUser> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _api.post('auth/verify-otp', {
      'email': email,
      'otp': otp,
    });
    return _authenticatedUser(result);
  }

  Future<void> resendOtp(String email) {
    return _api.post('auth/resend-otp', {'email': email}).then((_) {});
  }

  Future<AppUser> _authenticatedUser(Map<String, dynamic> result) async {
    final user = AppUser.fromJson(result['user'] as Map<String, dynamic>);
    final token = result['token']?.toString() ?? '';

    if (user.role != 'customer' || token.isEmpty) {
      await ApiTokenStore.clear();
      throw ApiException(
        'هذا الحساب غير مصرح له باستخدام تطبيق الزبون.',
        403,
        result,
      );
    }

    await ApiTokenStore.write(token);
    final firebaseToken = result['firebase_token']?.toString() ?? '';
    if (firebaseToken.isNotEmpty && FirebaseRuntime.isReady) {
      try {
        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
      } catch (_) {
        // Laravel remains authoritative. A temporary Firebase/Auth setup
        // failure must never prevent an otherwise valid application login.
      }
    }
    return user;
  }
}
