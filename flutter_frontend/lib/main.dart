import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/backend_api.dart';
import 'services/env_service.dart';
import 'services/fcm_service.dart';
import 'services/local_notifications_service.dart';
import 'services/token_store.dart';

/// Background message handler must be a top-level function.
/// It is invoked by the platform when a push arrives and the app is not in the foreground.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in background isolate before using other Firebase services.
  await Firebase.initializeApp();

  // In background we generally do NOT show a local notification because:
  // - On Android, FCM displays notification payloads automatically when app is backgrounded.
  // - For data-only messages you may want to display one; we keep this as a hook.
  // If needed, implement LocalNotificationsService().showFromRemoteMessage(message).
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvService.instance.load();

  // Ensure Firebase is initialized for FCM token + message streams.
  await Firebase.initializeApp();

  // Setup local notifications before registering message listeners.
  await LocalNotificationsService.instance.initialize();

  // Must be registered early (before runApp) for background handling.
  FcmService.registerBackgroundHandler(firebaseMessagingBackgroundHandler);

  runApp(const PushDemoApp());
}

class PushDemoApp extends StatelessWidget {
  const PushDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Push Notifications Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PushHomePage(),
    );
  }
}

class PushHomePage extends StatefulWidget {
  const PushHomePage({super.key});

  @override
  State<PushHomePage> createState() => _PushHomePageState();
}

class _PushHomePageState extends State<PushHomePage> {
  bool _isInitializing = true;
  bool _permissionGranted = false;

  String _fcmToken = '';
  String _lastMessage = 'No messages yet.';
  String _status = 'Starting…';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Per "async context" rules, we only update primitive state after awaits.
    try {
      final permissionGranted = await FcmService.instance.requestPermissions();
      final token = await FcmService.instance.getOrFetchToken();

      await TokenStore.instance.saveFcmToken(token);

      // "Persist/sync hook": call backend stub if configured.
      // This mirrors the Kotlin behavior where token gets updated to Firestore.
      // In Flutter we keep it backend-driven (no client OAuth/service-account).
      await BackendApi.instance.syncFcmToken(token);

      // Foreground: show local notification + update UI status.
      FcmService.instance.configureForegroundHandler(
        onForegroundMessage: (message, notificationShown) async {
          // Only update primitive fields here; no context operations.
          final title = message.notification?.title ?? 'Notification';
          final body = message.notification?.body ?? '(no body)';
          setState(() {
            _lastMessage = 'Foreground message: $title — $body';
            _status = notificationShown
                ? 'Foreground notification displayed.'
                : 'Foreground message received (no notification payload).';
          });
        },
      );

      // Tap/open: user taps notification and app opens/resumes.
      FcmService.instance.configureTapHandler(
        onNotificationTap: (message) async {
          final title = message.notification?.title ?? 'Notification';
          final body = message.notification?.body ?? '(no body)';
          setState(() {
            _lastMessage = 'Opened via notification tap: $title — $body';
            _status = 'Handled notification tap.';
          });
        },
      );

      setState(() {
        _permissionGranted = permissionGranted;
        _fcmToken = token;
        _status = 'Ready.';
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization error: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _refreshToken() async {
    try {
      setState(() {
        _status = 'Refreshing token…';
      });

      final token = await FcmService.instance.refreshToken();
      await TokenStore.instance.saveFcmToken(token);
      await BackendApi.instance.syncFcmToken(token);

      setState(() {
        _fcmToken = token;
        _status = 'Token refreshed and synced.';
      });
    } catch (e) {
      setState(() {
        _status = 'Token refresh failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Push Demo'),
        backgroundColor: scheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _InfoCard(
                    title: 'Status',
                    child: Text(_status),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Permission',
                    child: Text(
                      _permissionGranted
                          ? 'Granted'
                          : 'Not granted (or provisional/denied).',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'FCM Token (stored + sync hook)',
                    child: SelectableText(
                      _fcmToken.isEmpty ? '(empty)' : _fcmToken,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refreshToken,
                    child: const Text('Refresh FCM token'),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Last message',
                    child: Text(_lastMessage),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Backend stub configuration',
                    child: Text(
                      BackendApi.instance.isConfigured
                          ? 'Configured: ${BackendApi.instance.baseUrl}'
                          : 'Not configured. Set NOTIF_BACKEND_BASE_URL in .env.',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
