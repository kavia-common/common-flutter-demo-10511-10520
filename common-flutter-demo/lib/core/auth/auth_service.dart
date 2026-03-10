import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';

/// PUBLIC_INTERFACE
class DeviceSecurityStatus {
  /// PUBLIC_INTERFACE
  const DeviceSecurityStatus({
    required this.isAndroid,
    required this.osDescription,
    required this.canCheckBiometrics,
    required this.isDeviceSupported,
    required this.hasEnrolledBiometrics,
    required this.isDeviceSecure,
    required this.canAuthenticateWithBiometricOrDeviceCredential,
  });

  final bool isAndroid;
  final String osDescription;

  /// Whether the OS can check biometrics (API capability).
  final bool canCheckBiometrics;

  /// Whether this device supports local_auth at all.
  final bool isDeviceSupported;

  /// Whether user has enrolled biometrics (fingerprint/face).
  final bool hasEnrolledBiometrics;

  /// Whether device has secure lock screen (PIN/Pattern/Password).
  /// On Android this maps to Keyguard secure behind the scenes.
  final bool isDeviceSecure;

  /// A practical "available" indicator similar to the Kotlin app:
  /// - true if local_auth reports device is supported AND device is secure
  /// - and authentication can be attempted using biometrics or device credential
  final bool canAuthenticateWithBiometricOrDeviceCredential;
}

/// PUBLIC_INTERFACE
class AuthService {
  /// PUBLIC_INTERFACE
  AuthService({
    LocalAuthentication? localAuth,
    DeviceInfoPlugin? deviceInfo,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final LocalAuthentication _localAuth;
  final DeviceInfoPlugin _deviceInfo;

  // PUBLIC_INTERFACE
  Future<DeviceSecurityStatus> getDeviceSecurityStatus() async {
    final bool isAndroid = Platform.isAndroid;

    String osDesc = 'Unknown OS';
    if (isAndroid) {
      final android = await _deviceInfo.androidInfo;
      osDesc = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      osDesc = 'iOS ${ios.systemVersion}';
    } else {
      osDesc = Platform.operatingSystem;
    }

    final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final bool isDeviceSupported = await _localAuth.isDeviceSupported();

    final List<BiometricType> availableBiometrics =
        await _localAuth.getAvailableBiometrics();
    final bool hasEnrolledBiometrics = availableBiometrics.isNotEmpty;

    // local_auth exposes "device is secure" on Android; on iOS it always
    // returns true if the device supports passcode/biometrics.
    final bool isDeviceSecure = await _localAuth.isDeviceSupported() &&
        (await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported())
        ? await _localAuth.isDeviceSupported()
        : false;

    // Better: ask explicitly for device security where supported.
    // `isDeviceSupported` just indicates hardware + platform support.
    // `isDeviceSecure` is not directly exposed for all platforms;
    // local_auth provides `isDeviceSupported` and the authenticate call
    // will fail if lock screen is not set when using device credentials.
    //
    // We'll approximate:
    // - If biometrics are enrolled => assume secure
    // - On Android, if device is supported but no biometrics, still may be secure via device credential.
    // The definitive check is attempting authenticate() with `biometricOnly: false`.
    final bool canAuthenticateWithBiometricOrDeviceCredential =
        isDeviceSupported && (canCheckBiometrics || isAndroid);

    return DeviceSecurityStatus(
      isAndroid: isAndroid,
      osDescription: osDesc,
      canCheckBiometrics: canCheckBiometrics,
      isDeviceSupported: isDeviceSupported,
      hasEnrolledBiometrics: hasEnrolledBiometrics,
      isDeviceSecure: hasEnrolledBiometrics || (isAndroid && isDeviceSupported),
      canAuthenticateWithBiometricOrDeviceCredential:
          canAuthenticateWithBiometricOrDeviceCredential,
    );
  }

  /// Attempts authentication using biometrics OR device credential fallback.
  ///
  /// On Android, `biometricOnly: false` allows using the system credential
  /// (PIN/Pattern/Password) fallback where supported.
  ///
  /// PUBLIC_INTERFACE
  Future<bool> authenticate({
    required String localizedReason,
  }) async {
    final bool didAuthenticate = await _localAuth.authenticate(
      localizedReason: localizedReason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
    return didAuthenticate;
  }
}
