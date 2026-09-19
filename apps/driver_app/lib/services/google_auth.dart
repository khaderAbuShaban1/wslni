part of '../main.dart';

/// The Web OAuth client ID of the Firebase project (Authentication → Google).
/// It is public, not a secret; the backend accepts ID tokens issued for it.
const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '507815627313-5bsgk616v3iuh2a4ebmojfj0g7mqnocp.apps.googleusercontent.com',
);

class _GoogleAuth {
  static Future<void>? _initialized;

  static bool get isConfigured => _googleServerClientId.isNotEmpty;

  static Future<void> _ensureInitialized() => _initialized ??= GoogleSignIn
      .instance
      .initialize(serverClientId: _googleServerClientId);

  /// Returns a Google ID token, or null when the user closes the picker.
  static Future<String?> idToken() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Forgets the chosen account so the next sign-in shows the picker again.
  static Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out of the app must never fail because of Google.
    }
  }
}
