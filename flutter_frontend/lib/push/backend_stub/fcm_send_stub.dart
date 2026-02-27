import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Backend stub for sending pushes.
///
/// IMPORTANT:
/// In the Kotlin sample, the client uses a service account OAuth token to call
/// FCM v1 directly. That is not safe for a mobile client. This stub expects a
/// backend endpoint that performs the OAuth signing and calls FCM v1.
///
/// Configure your backend and set a URL here (or via your own env/config system).
class FcmSendBackendStub {
  static const String _endpointUrl = String.fromEnvironment(
    'PUSH_BACKEND_URL',
    defaultValue: '',
  );

  // PUBLIC_INTERFACE
  static Future<void> sendTestNotification() async {
    /// Sends a test notification request to a backend endpoint.
    ///
    /// If `_endpointUrl` is empty, this will simply log and return.
    if (_endpointUrl.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'PUSH_BACKEND_URL not set. Provide --dart-define=PUSH_BACKEND_URL=https://your-backend/sendPush',
        );
      }
      return;
    }

    final uri = Uri.parse(_endpointUrl);

    // Example payload: backend decides actual target token/user.
    final payload = <String, dynamic>{
      'title': 'flutter_frontend',
      'body': 'Test push from backend stub',
      'data': <String, dynamic>{'source': 'flutter'},
    };

    final resp = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('Backend stub response: ${resp.statusCode} ${resp.body}');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Backend stub failed (${resp.statusCode}): ${resp.body}');
    }
  }
}
