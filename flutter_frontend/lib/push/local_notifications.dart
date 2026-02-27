import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  LocalNotifications._();

  static final LocalNotifications instance = LocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'fcm_default_channel',
    'FCM Default',
    description: 'Default channel for FCM notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;

  // PUBLIC_INTERFACE
  Future<void> initialize() async {
    /// Initialize local notifications plugin and create Android channel.
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_defaultChannel);
  }

  // PUBLIC_INTERFACE
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    /// Display a local notification.
    const androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'FCM Default',
      channelDescription: 'Default channel for FCM notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      details,
      payload: payload == null ? null : payload.toString(),
    );
  }
}
