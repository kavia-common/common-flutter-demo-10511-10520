import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notifications_service.dart';

typedef ForegroundMessageCallback = Future<void> Function(
  RemoteMessage message,
  bool notificationShown,
);

typedef NotificationTapCallback = Future<void> Function(RemoteMessage message);

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  /// PUBLIC_INTERFACE
  static void registerBackgroundHandler(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    /// Registers the background handler for FCM messages.
    ///
    /// Must be called before `runApp` and the handler must be a top-level function.
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  /// PUBLIC_INTERFACE
  Future<bool> requestPermissions() async {
    /// Requests OS-level notification permissions (esp. iOS; Android 13+ is also runtime).
    ///
    /// Returns true if authorization is granted or provisional.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// PUBLIC_INTERFACE
  Future<String> getOrFetchToken() async {
    /// Returns current FCM token or fetches a new one.
    final token = await _messaging.getToken();
    return token ?? '';
  }

  /// PUBLIC_INTERFACE
  Future<String> refreshToken() async {
    /// Forces a token refresh and returns the new token.
    await _messaging.deleteToken();
    final token = await _messaging.getToken();
    return token ?? '';
  }

  /// PUBLIC_INTERFACE
  void configureForegroundHandler({
    required ForegroundMessageCallback onForegroundMessage,
  }) {
    /// Configures a listener for foreground messages.
    ///
    /// When a notification is received while app is in foreground, we show a local
    /// notification (Android/iOS) using flutter_local_notifications so the user
    /// still sees an alert like they would in background.
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      final shown =
          await LocalNotificationsService.instance.showFromRemoteMessage(message);
      await onForegroundMessage(message, shown);
    });
  }

  /// PUBLIC_INTERFACE
  void configureTapHandler({required NotificationTapCallback onNotificationTap}) {
    /// Configures handlers for notification-tap/open flows:
    /// - From background: `onMessageOpenedApp`
    /// - From terminated: `getInitialMessage`
    _tapSub?.cancel();

    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await onNotificationTap(message);
    });

    // Also handle cold start.
    unawaited(_handleInitialMessage(onNotificationTap));
  }

  Future<void> _handleInitialMessage(NotificationTapCallback callback) async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await callback(initialMessage);
    }
  }
}
