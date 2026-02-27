# iOS Push Notifications (Firebase Messaging) + Local Notifications setup

This Flutter project uses:
- `firebase_messaging` for FCM/APNs push notifications
- `flutter_local_notifications` for foreground/local notifications

As of this commit, a real `ios/Runner` project exists and includes baseline native configuration. You still must perform a few manual Firebase/Xcode steps (below) because Apple signing/capabilities and Firebase config files cannot be fully generated from code alone.

---

## 1) Add Firebase config file (required)

Download **GoogleService-Info.plist** from Firebase Console and place it at:

`ios/Runner/GoogleService-Info.plist`

Then in Xcode:
- Open `ios/Runner.xcworkspace`
- Ensure `GoogleService-Info.plist` is added to the **Runner** target (File Inspector → Target Membership).

The iOS `AppDelegate.swift` calls `FirebaseApp.configure()` and expects this file to be present.

---

## 2) App capabilities (MANUAL Xcode steps required)

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select **Runner** target → **Signing & Capabilities**
3. Add capability: **Push Notifications**
4. Add capability: **Background Modes** and enable:
   - **Remote notifications**

Notes:
- This typically creates/updates `Runner.entitlements` and sets `aps-environment`.
- This also requires a valid Apple Developer Team and correct provisioning profiles.

---

## 3) APNs key/cert + Firebase Console mapping (MANUAL)

To receive remote push notifications on iOS devices:

1. Apple Developer portal:
   - Create an **APNs Auth Key** (recommended) *or* APNs certificates.
2. Firebase Console → Project Settings → Cloud Messaging:
   - Upload APNs Auth Key (or certificates)
   - Ensure your iOS bundle id matches your app’s bundle id (Xcode Runner target → General → Bundle Identifier)

---

## 4) Info.plist keys already included

`ios/Runner/Info.plist` includes:
- `NSUserNotificationUsageDescription`
- `UIBackgroundModes` with `remote-notification`

Permission is still requested at runtime by Dart code (`FirebaseMessaging.instance.requestPermission(...)`).

---

## 5) CocoaPods install (required)

From `common-flutter-demo-10511-10520/flutter_frontend/ios`:

```bash
pod repo update
pod install
```

Then always open:
- `ios/Runner.xcworkspace` (not `Runner.xcodeproj`)

---

## 6) Testing notes

- Remote push notifications require a **real iOS device** (simulator support is limited and depends on iOS version; do not rely on it).
- Foreground notifications are displayed via `flutter_local_notifications` (already implemented in Dart).
- Background handler is registered via `FirebaseMessaging.onBackgroundMessage(...)` (already in Dart).

---

## Troubleshooting tips

- If pods fail due to iOS minimum version, keep `platform :ios, '12.0'` (or raise it if required by plugin versions).
- If you see Firebase not configured errors, confirm `GoogleService-Info.plist` is in `ios/Runner/` and included in the Runner target.
- If token/APNs issues occur, confirm Push Notifications capability is enabled and provisioning profiles include it.
