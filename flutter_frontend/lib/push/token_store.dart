import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const String _tokenKey = 'fcm_token';

  // PUBLIC_INTERFACE
  Future<void> saveToken(String token) async {
    /// Persist the FCM token locally.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // PUBLIC_INTERFACE
  Future<String?> getToken() async {
    /// Retrieve the locally persisted FCM token.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
