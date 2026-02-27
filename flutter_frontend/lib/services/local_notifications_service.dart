import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'fcm_default_channel';
  static const String _channelName = 'FCM Default';
  static const String _channelDescription = 'Foreground notifications channel';

  /// PUBLIC_INTERFACE
  Future<void> initialize() async {
    /// Initializes flutter_local_notifications and creates Android channel.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();

    const initSettings =
        InitializationSettings(android: androidInit, iOS: iOSInit);

    await _plugin.initialize(initSettings);

    // Android channel creation (no-op on iOS).
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);

    // On iOS we still rely on FirebaseMessaging.requestPermission for notification
    // authorization; local notifications permission can be requested separately if desired.
  }

  /// PUBLIC_INTERFACE
  Future<bool> showFromRemoteMessage(RemoteMessage message) async {
    /// Shows a local notification for a foreground FCM message when possible.
    ///
    /// Returns true if a local notification was shown.
    if (kIsWeb) {
      return false;
    }

    final notification = message.notification;
    if (notification == null) {
      return false;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iOSDetails = DarwinNotificationDetails();

    final details =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _plugin.show(
      // Keep it stable-ish; if messageId is absent, fall back to hashCode.
      (message.messageId ?? message.hashCode.toString()).hashCode,
      notification.title ?? 'Notification',
      notification.body ?? '',
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );

    return true;
  }
}
