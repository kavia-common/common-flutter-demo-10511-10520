import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/push/token_store.dart';
import 'package:flutter_frontend/push/local_notifications.dart';

/// Background handler for FCM messages.
///
/// Must be a top-level function.
/// See: https://firebase.flutter.dev/docs/messaging/overview/#handling-messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in the background isolate.
  await Firebase.initializeApp();

  // Local notifications need to be initialized in this isolate as well.
  await LocalNotifications.instance.initialize();

  final title = message.notification?.title ?? 'Notification';
  final body = message.notification?.body ?? 'You received a message.';
  await LocalNotifications.instance.showNotification(
    title: title,
    body: body,
    payload: message.data,
  );
}

/// Singleton service that owns all FCM setup and exposes streams for UI.
///
/// Mirrors the Kotlin Connected_Living behavior:
/// - onMessageReceived: show a notification
/// - onNewToken: log/store token and optionally update backend
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  /// Stream of the current FCM token (and future refreshes).
  Stream<String?> get tokenStream => _tokenController.stream;

  /// Stream of human-readable incoming message summaries for the UI.
  Stream<String> get messageStream => _messageController.stream;

  bool _initialized = false;

  // PUBLIC_INTERFACE
  Future<void> initialize() async {
    /// Initializes Firebase + FCM + local notifications handlers.
    ///
    /// Safe to call multiple times.
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    await LocalNotifications.instance.initialize();

    // iOS/macOS permission request (Android 13+ is handled by the plugin too).
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('FCM permission status: ${settings.authorizationStatus}');
    }

    // Ensure background messages are handled.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // When app is in foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? 'You received a message.';

      _messageController.add('$title: $body');

      await LocalNotifications.instance.showNotification(
        title: title,
        body: body,
        payload: message.data,
      );
    });

    // When user taps a notification to open the app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification opened';
      final body = message.notification?.body ?? '';
      _messageController.add('$title $body'.trim());
    });

    // Load any previously stored token.
    final storedToken = await TokenStore.instance.getToken();
    _tokenController.add(storedToken);

    // Attempt refresh now.
    await refreshToken();

    // Listen for token refreshes.
    messaging.onTokenRefresh.listen((token) async {
      await TokenStore.instance.saveToken(token);
      _tokenController.add(token);

      if (kDebugMode) {
        // ignore: avoid_print
        print('FCM token refreshed: $token');
      }
    });
  }

  // PUBLIC_INTERFACE
  Future<void> refreshToken() async {
    /// Fetches the latest FCM token and persists it locally.
    ///
    /// This is the Flutter equivalent of Connected_Living's `getFcmToken()`.
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _tokenController.add(null);
        return;
      }
      await TokenStore.instance.saveToken(token);
      _tokenController.add(token);
    } catch (_) {
      // Keep errors non-fatal for scaffold usage.
      _tokenController.add(null);
    }
  }

  void dispose() {
    _tokenController.close();
    _messageController.close();
  }
}
