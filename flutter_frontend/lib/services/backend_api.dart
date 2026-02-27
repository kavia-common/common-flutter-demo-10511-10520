import 'dart:convert';

import 'package:http/http.dart' as http;

import 'env_service.dart';

class BackendApi {
  BackendApi._();

  static final BackendApi instance = BackendApi._();

  String? get baseUrl => EnvService.instance.getString('NOTIF_BACKEND_BASE_URL');

  bool get isConfigured => baseUrl != null;

  /// PUBLIC_INTERFACE
  Future<void> syncFcmToken(String token) async {
    /// Persists the token to your backend (stub).
    ///
    /// This replaces the Kotlin approach of updating Firestore directly from client.
    /// Expected endpoint (example):
    ///   POST {NOTIF_BACKEND_BASE_URL}/v1/notifications/token
    /// Body:
    ///   { "token": "<fcm-token>" }
    ///
    /// If the backend URL is not configured, this method is a no-op.
    final url = baseUrl;
    if (url == null || token.trim().isEmpty) {
      return;
    }

    final uri = Uri.parse('$url/v1/notifications/token');
    await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
  }

  /// PUBLIC_INTERFACE
  Future<void> requestSendNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    /// Requests the backend to send a push notification (stub).
    ///
    /// Expected endpoint (example):
    ///   POST {NOTIF_BACKEND_BASE_URL}/v1/notifications/send
    /// Body:
    ///   { "token": "...", "title": "...", "body": "...", "data": {...} }
    ///
    /// If backend URL is not configured, this method is a no-op.
    final url = baseUrl;
    if (url == null) {
      return;
    }

    final uri = Uri.parse('$url/v1/notifications/send');
    await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': targetToken,
        'title': title,
        'body': body,
        'data': data ?? <String, String>{},
      }),
    );
  }
}
