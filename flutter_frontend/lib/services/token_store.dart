import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const String _keyFcmToken = 'fcm_token';

  /// PUBLIC_INTERFACE
  Future<void> saveFcmToken(String token) async {
    /// Saves the FCM token locally.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, token);
  }

  /// PUBLIC_INTERFACE
  Future<String> readFcmToken() async {
    /// Reads the stored FCM token (or empty string if missing).
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken) ?? '';
  }
}
