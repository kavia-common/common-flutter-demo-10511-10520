import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase must be configured on iOS for Firebase Messaging to work.
    // This expects ios/Runner/GoogleService-Info.plist to be present and included in the Runner target.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    // Keep FlutterAppDelegate behavior (including plugin hooks).
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
