import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func registerPlugins(_ registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
  }
}
