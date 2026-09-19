part of '../main.dart';

/// Simple local state kept in SharedPreferences. The API token itself stays
/// in secure storage ([ApiTokenStore]); only non-secret data lives here.
class _SessionStore {
  static const _loggedInKey = 'session_logged_in';
  static const _userKey = 'session_user';
  static const _lastEmailKey = 'last_login_email';

  static Future<void> saveUser(DriverUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_lastEmailKey, user.email);
  }

  /// The signed-in driver from the last session, if its token is still stored.
  static Future<DriverUser?> restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (prefs.getBool(_loggedInKey) != true || raw == null) return null;

    final token = await ApiTokenStore.read();
    if (token == null || token.isEmpty) {
      await clear();
      return null;
    }

    try {
      return DriverUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  /// Ends the local session but keeps the last email for the login form.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userKey);
  }

  static Future<String> lastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmailKey) ?? '';
  }
}

/// Opens the home page straight away when a session was saved.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<DriverUser?> _session = _SessionStore.restoreUser();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverUser?>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null ? const AuthPage() : DriverHomePage(user: user);
      },
    );
  }
}
