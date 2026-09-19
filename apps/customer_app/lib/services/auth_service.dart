import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/firebase_runtime.dart';
import 'api_client.dart';
import 'google_auth.dart';
import 'notification_service.dart';
import 'session_store.dart';

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

  /// Null when the user closed the Google account picker.
  Future<AppUser?> loginWithGoogle() async {
    if (!GoogleAuth.isConfigured) {
      throw ApiException('تسجيل الدخول عبر Google غير مفعّل بعد.', 503, {});
    }
    final idToken = await GoogleAuth.idToken();
    if (idToken == null) return null;

    final result = await _api.post('auth/google', {
      'id_token': idToken,
      'role': 'customer',
    });
    return _authenticatedUser(result);
  }

  Future<String> requestPasswordReset(String email) async {
    final result = await _api.post('auth/forgot-password', {'email': email});
    return result['message']?.toString() ?? '';
  }

  /// Returns the short-lived token needed to set the new password.
  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final result = await _api.post('auth/forgot-password/verify', {
      'email': email,
      'code': code,
    });
    return result['reset_token'].toString();
  }

  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _api.post('auth/reset-password', {
      'email': email,
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return result['message']?.toString() ?? '';
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

    // Register FCM token for push notifications.
    await NotificationService.instance.registerToken();
    await SessionStore.saveUser(user);

    return user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _api
        .post('auth/change-password', {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        })
        .then((_) {});
  }
}
