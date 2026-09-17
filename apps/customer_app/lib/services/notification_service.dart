import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// Handles background FCM messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class NotificationService with WidgetsBindingObserver {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service. Call once after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Request permission (iOS / Android 13+).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Set up local notifications for foreground display.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'wslni_notifications',
            'إشعارات وصّلني',
            description: 'إشعارات الرحلات والمحفظة',
            importance: Importance.high,
          ),
        );

    // Background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages — show a local notification.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When the user taps a notification that opened the app.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if the app was opened from a terminated state by a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }

    // A device has one FCM token, so another account signing in on this device
    // takes it over. Re-claiming it on every resume keeps it bound to whoever
    // is currently signed in here.
    WidgetsBinding.instance.addObserver(this);
    await _registerIfSignedIn();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _registerIfSignedIn();
    }
  }

  Future<void> _registerIfSignedIn() async {
    final authToken = await ApiTokenStore.read();
    if (authToken != null && authToken.isNotEmpty) {
      await registerToken();
    }
  }

  bool _tokenListenerActive = false;

  /// Get the current FCM token and register it with the backend.
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _sendTokenToBackend(token);
      }

      if (!_tokenListenerActive) {
        _tokenListenerActive = true;
        _messaging.onTokenRefresh.listen(_sendTokenToBackend);
      }
    } catch (e) {
      debugPrint('FCM token registration error: $e');
    }
  }

  /// Unregister the FCM token (call on logout).
  Future<void> unregisterToken() async {
    try {
      final api = ApiClient();
      await api.delete('fcm/token');
    } catch (_) {}
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final api = ApiClient();
      await api.post('fcm/token', {'token': token});
      debugPrint('FCM token registered with backend.');
    } catch (e) {
      debugPrint('FCM token send error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wslni_notifications',
          'إشعارات وصّلني',
          channelDescription: 'إشعارات الرحلات والمحفظة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.data}');
    // Navigation can be handled here based on message.data['type'].
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Navigation can be handled here based on the payload.
  }
}
