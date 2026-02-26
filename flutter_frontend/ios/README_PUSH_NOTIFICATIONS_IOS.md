# iOS Push Notifications (Firebase Messaging) + Local Notifications setup

This Flutter project uses:
- `firebase_messaging` for FCM/APNs push notifications
- `flutter_local_notifications` for foreground/local notifications

## Current repo state
The `ios/` folder is currently missing from the repository, so iOS cannot be configured/compiled here until it is re-generated or added back.

If you previously had an iOS Runner, **restore/commit** your `ios/` directory, or regenerate it with:

```bash
flutter create .
```

(Do this in `common-flutter-demo-10511-10520/flutter_frontend/`.)

After the `ios/` folder exists, apply the steps below.

---

## 1) Add Firebase config file (required)
Download **GoogleService-Info.plist** from Firebase Console and place it at:

`ios/Runner/GoogleService-Info.plist`

Also ensure it is added to the Runner target in Xcode (it must appear under Runner in the project navigator).

---

## 2) Info.plist keys (required for local notifications / permissions)
Edit:

`ios/Runner/Info.plist`

Add (or ensure) these keys exist:

- `NSUserNotificationUsageDescription` (optional but recommended; iOS may show system prompts depending on iOS version/features)
- `UIBackgroundModes` includes `remote-notification` (recommended for background message handling / silent pushes)

Example snippet:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

Notes:
- For iOS push notifications, permission is requested at runtime by `FirebaseMessaging.instance.requestPermission(...)` (already present in Dart code via `FcmService`).

---

## 3) AppDelegate setup (Firebase + APNs token bridging)
Open:

`ios/Runner/AppDelegate.swift` (or `AppDelegate.m` for Obj-C)

### Swift (typical modern Flutter template)
Ensure it contains Firebase initialization and notification delegation hooks.

Minimum expected shape (illustrative):

```swift
import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Required for plugin registration
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Additional notes:
- `firebase_messaging` typically handles most wiring automatically, but Firebase initialization (`FirebaseApp.configure()`) is required when not using generated firebase options.
- If you use `flutterfire configure`, it may generate different code paths (e.g., `FirebaseApp.configure()` still required, but options handled via generated files).

---

## 4) Capabilities / Entitlements (MANUAL Xcode steps required)
These cannot be fully enabled via text files alone because they depend on Xcode project signing.

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select `Runner` target → **Signing & Capabilities**
3. Add capabilities:
   - **Push Notifications**
   - **Background Modes** → enable **Remote notifications**

This will update:
- `Runner.entitlements` (created/modified by Xcode)
- project capabilities metadata

### If `Runner.entitlements` exists, it should contain at least:
- `aps-environment` (value: `development` or `production` depending on build)

Xcode usually manages this automatically.

---

## 5) APNs key/cert + Firebase Console mapping (MANUAL)
To receive push notifications on iOS:
1. In Apple Developer portal: create an **APNs Auth Key** (recommended) or certificates
2. In Firebase Console → Project Settings → Cloud Messaging:
   - Upload APNs Auth Key (or certificates)
   - Ensure your iOS bundle id matches the app’s bundle id

---

## 6) CocoaPods install (required after adding Firebase)
From `ios/` directory:

```bash
pod repo update
pod install
```

Then open `Runner.xcworkspace` (not `.xcodeproj`).

---

## 7) Testing notes
- Simulator: APNs push notifications generally require a real device (especially for remote push).
- Foreground notifications: this project shows notifications in foreground via `flutter_local_notifications` (already implemented in Dart).
- Background handler: Dart already registers `FirebaseMessaging.onBackgroundMessage(...)`.

---

## What is already handled by Dart code
The existing Dart implementation:
- Initializes Firebase on startup (`Firebase.initializeApp()`)
- Registers a background handler
- Requests notification permissions
- Uses `flutter_local_notifications` for foreground display

So after the iOS native setup above, **no Dart changes should be required**.
