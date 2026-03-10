# common-flutter-demo

A Flutter migration of the **Connected_Living** (Biometric Authentication Android) demo.

## Features mirrored from the Kotlin app
- Device security status checks (Android-focused):
  - Biometric capability available (hardware + enrolled biometrics OR device credential)
  - Device has secure screen lock (PIN/Pattern/Password)
- Biometric authentication flow with device-credential fallback where supported
- Simple UI with status indicators + Authenticate button + snackbar feedback

## Plugins used
- `local_auth` (+ `local_auth_android`): biometric + device credential authentication
- `device_info_plus`: OS/device info for display/debug and capability gating

## Run
```bash
cd common-flutter-demo-10511-10520/common-flutter-demo
flutter pub get
flutter run
```

## Notes
- iOS requires additional setup for Face ID/Touch ID usage descriptions (Info.plist). This demo focuses on Android parity with Connected_Living.
"""
