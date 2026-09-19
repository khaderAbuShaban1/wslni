import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_client.dart';

/// Simple local state kept in SharedPreferences. The API token itself stays
/// in secure storage ([ApiTokenStore]); only non-secret data lives here.
class SessionStore {
  static const _loggedInKey = 'session_logged_in';
  static const _userKey = 'session_user';
  static const _lastEmailKey = 'last_login_email';
  static const _onboardingSeenKey = 'onboarding_seen';

  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_lastEmailKey, user.email);
  }

  /// The signed-in user from the last session, if its token is still stored.
  static Future<AppUser?> restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (prefs.getBool(_loggedInKey) != true || raw == null) return null;

    final token = await ApiTokenStore.read();
    if (token == null || token.isEmpty) {
      await clear();
      return null;
    }

    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  /// Ends the local session but keeps settings and the last email.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userKey);
  }

  static Future<String> lastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmailKey) ?? '';
  }

  static Future<bool> onboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
