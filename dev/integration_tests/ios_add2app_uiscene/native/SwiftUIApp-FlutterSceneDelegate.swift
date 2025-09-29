//
//  xcode_swiftuiApp.swift
//  xcode_swiftui
//
//  Created by Victoria Ashworth on 9/28/25.
//

import Flutter
import FlutterPluginRegistrant
import SwiftUI

@Observable
class AppDelegate: FlutterAppDelegate {
  let flutterEngine = FlutterEngine(name: "my flutter engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication
      .LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: self.flutterEngine)
    return true
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(
      name: nil,
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = FlutterSceneDelegate.self
    return configuration
  }
}

@main
struct xcode_swiftuiApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
