import 'package:flutter/material.dart';
import 'package:flutter_frontend/push/backend_stub/fcm_send_stub.dart';
import 'package:flutter_frontend/push/push_notification_service.dart';

/// Flutter app entrypoint.
///
/// This app bootstraps Firebase Cloud Messaging (FCM) handlers to:
/// - request notification permissions,
/// - obtain/persist the FCM token,
/// - display local notifications for incoming messages,
/// - provide a backend-stub call for sending pushes (server should do this in production).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize push notification services early so background handlers can work.
  await PushNotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'flutter_frontend';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PushDemoHomePage(),
    );
  }
}

class PushDemoHomePage extends StatefulWidget {
  const PushDemoHomePage({super.key});

  @override
  State<PushDemoHomePage> createState() => _PushDemoHomePageState();
}

class _PushDemoHomePageState extends State<PushDemoHomePage> {
  String _token = 'Loading…';
  String _lastMessage = 'No message received yet';

  @override
  void initState() {
    super.initState();

    // Subscribe to token & message updates. No context usage across async gaps.
    PushNotificationService.instance.tokenStream.listen((token) {
      setState(() {
        _token = token ?? 'No token yet (permission not granted?)';
      });
    });

    PushNotificationService.instance.messageStream.listen((msg) {
      setState(() {
        _lastMessage = msg;
      });
    });

    // Kick off a token refresh (non-blocking).
    PushNotificationService.instance.refreshToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_frontend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Push notifications (FCM) scaffold',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Token (persisted locally):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SelectableText(_token),
            const SizedBox(height: 16),
            const Text(
              'Last received message:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(_lastMessage),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                // Stub: in production, sending must happen on backend with service credentials.
                await FcmSendBackendStub.sendTestNotification();
              },
              child: const Text('Send test push via backend stub'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: This stub is expected to fail until you provide a real backend endpoint.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
