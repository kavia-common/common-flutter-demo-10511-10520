import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  EnvService._();

  static final EnvService instance = EnvService._();

  /// PUBLIC_INTERFACE
  Future<void> load() async {
    /// Loads environment variables from `.env`.
    ///
    /// Note: `.env` is included as a Flutter asset in pubspec.yaml.
    await dotenv.load(fileName: '.env');
  }

  /// PUBLIC_INTERFACE
  String? getString(String key) {
    /// Returns environment variable value if set, otherwise null.
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }
}
