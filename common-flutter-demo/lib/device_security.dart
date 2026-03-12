import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart wrapper for Android device security and biometric/device-credential auth.
///
/// Uses a MethodChannel implemented by the Android host app (MainActivity).
class DeviceSecurityApi {
  static const MethodChannel _channel = MethodChannel(
    'com.example.common_flutter_demo/device_security',
  );

  // PUBLIC_INTERFACE
  static Future<DeviceSecurityStatus> getSecurityStatus() async {
    /// Fetches current device security & authenticator availability status.
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getSecurityStatus',
    );
    if (raw == null) {
      throw StateError('Platform returned null security status');
    }
    return DeviceSecurityStatus.fromPlatformMap(raw);
  }

  // PUBLIC_INTERFACE
  static Future<AuthResult> authenticate({
    required String reason,
    bool allowDeviceCredential = true,
  }) async {
    /// Prompts the user to authenticate using biometrics, with optional device
    /// credential fallback (PIN/pattern/password) when supported.
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'authenticate',
      <String, Object?>{
        'reason': reason,
        'allowDeviceCredential': allowDeviceCredential,
      },
    );

    if (raw == null) {
      return const AuthResult(
        status: AuthStatus.error,
        errorMessage: 'Platform returned null authentication result',
      );
    }

    return AuthResult.fromPlatformMap(raw);
  }
}

enum AuthStatus { success, failed, canceled, error }

@immutable
class AuthResult {
  final AuthStatus status;
  final int? errorCode;
  final String? errorMessage;

  const AuthResult({
    required this.status,
    this.errorCode,
    this.errorMessage,
  });

  factory AuthResult.fromPlatformMap(Map<Object?, Object?> map) {
    final statusStr = (map['status'] as String?) ?? 'error';
    final status = switch (statusStr) {
      'success' => AuthStatus.success,
      'failed' => AuthStatus.failed,
      'canceled' => AuthStatus.canceled,
      _ => AuthStatus.error,
    };

    final errorCode = map['errorCode'];
    final errorMessage = map['errorMessage'];

    return AuthResult(
      status: status,
      errorCode: errorCode is int ? errorCode : null,
      errorMessage: errorMessage is String ? errorMessage : null,
    );
  }
}

@immutable
class DeviceSecurityStatus {
  final bool isDeviceSecure;
  final bool canBiometricStrong;
  final bool canDeviceCredential;
  final bool canStrongOrCredential;

  const DeviceSecurityStatus({
    required this.isDeviceSecure,
    required this.canBiometricStrong,
    required this.canDeviceCredential,
    required this.canStrongOrCredential,
  });

  factory DeviceSecurityStatus.fromPlatformMap(Map<Object?, Object?> map) {
    bool getBool(String key) => (map[key] as bool?) ?? false;

    return DeviceSecurityStatus(
      isDeviceSecure: getBool('isDeviceSecure'),
      canBiometricStrong: getBool('canBiometricStrong'),
      canDeviceCredential: getBool('canDeviceCredential'),
      canStrongOrCredential: getBool('canStrongOrCredential'),
    );
  }
}
