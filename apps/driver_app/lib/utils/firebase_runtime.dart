part of '../main.dart';

class FirebaseRuntime {
  FirebaseRuntime._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    if (_ready || Firebase.apps.isNotEmpty) {
      _ready = true;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: _FirebaseEnv.isConfigured
            ? _FirebaseEnv.options
            : DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }
}

class _FirebaseEnv {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const databaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');

  static bool get isConfigured {
    return apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty &&
        databaseUrl.isNotEmpty;
  }

  static FirebaseOptions get options {
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      databaseURL: databaseUrl,
    );
  }
}
