// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit

/// This test file verifies code compiles.

/// MARK: - @MainActor classes
@MainActor
func usableOnMainActor() {
  let _ = FlutterEngine()
  let _ = FlutterDartProject()
  let _ = FlutterEngineGroup(name: "test", project: nil)
  let _ = FlutterPluginAppLifeCycleDelegate()
  if #available(iOS 13.0, *) {
    let _ = FlutterPluginSceneLifeCycleDelegate()
    let _ = FlutterSceneDelegate()
  }
}

/// MARK: - @MainActor Protocol Witnesses

@MainActor
class ImplicitEngineDelegateImpl: FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ bridge: any FlutterImplicitEngineBridge) {
    let _ = bridge.applicationRegistrar
  }
}

@MainActor
class PluginImpl: NSObject, FlutterPlugin {
  static func register(with _: any FlutterPluginRegistrar) { }
  static func setPluginRegistrantCallback(_: @escaping FlutterPluginRegistrantCallback) { }
  func handle(_: FlutterMethodCall, result: @escaping FlutterResult) { }
  func detachFromEngine(for _: any FlutterPluginRegistrar) { }
}

@MainActor
class PlatformViewImpl: NSObject, FlutterPlatformView {
  func view() -> UIView { UIView() }
}

@MainActor
class PlatformViewFactoryImpl: NSObject, FlutterPlatformViewFactory {
  func create(withFrame _: CGRect, viewIdentifier _: Int64, arguments _: Any?) -> any FlutterPlatformView {
    PlatformViewImpl()
  }
  
  func createArgsCodec() -> any FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

@MainActor
class ApplicationLifeCycleDelegateImpl: NSObject, FlutterApplicationLifeCycleDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [AnyHashable : Any]) -> Bool { true }
  func application(_ application: UIApplication, willFinishLaunchingWithOptions _: [AnyHashable : Any]) -> Bool { true }
  
  func applicationDidBecomeActive(_: UIApplication) {}
  func applicationWillResignActive(_: UIApplication) {}
  func applicationDidEnterBackground(_: UIApplication) {}
  func applicationWillEnterForeground(_: UIApplication) {}
  func applicationWillTerminate(_: UIApplication) {}
  func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken _: Data) {}
  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}
  func application(_: UIApplication, didReceiveRemoteNotification _: [AnyHashable : Any], fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) -> Bool { true }
  func application(_: UIApplication, open _: URL, options _: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool { true }
  func application(_: UIApplication, handleOpen _: URL) -> Bool { true }
  func application(_: UIApplication, open _: URL, sourceApplication _: String, annotation _: Any) -> Bool { true }
  func application(_: UIApplication, performActionFor _: UIApplicationShortcutItem, completionHandler _: @escaping (Bool) -> Void) -> Bool { true }
  func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler _: @escaping () -> Void) -> Bool { true }
  func application(_: UIApplication, performFetchWithCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) -> Bool { true }
  func application(_: UIApplication, continue _: NSUserActivity, restorationHandler _: @escaping ([Any]) -> Void) -> Bool { true }
}

@available(iOS 13.0, *)
@MainActor
class SceneLifeCycleDelegateImpl: NSObject, FlutterSceneLifeCycleDelegate {
  func scene(_: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions?) -> Bool { true }
  func sceneDidDisconnect(_: UIScene) {}
  func sceneWillEnterForeground(_: UIScene) {}
  func sceneDidBecomeActive(_: UIScene) {}
  func sceneWillResignActive(_: UIScene) {}
  func sceneDidEnterBackground(_: UIScene) {}
  func scene(_: UIScene, openURLContexts _: Set<UIOpenURLContext>) -> Bool { true }
  func scene(_: UIScene, continue _: NSUserActivity) -> Bool { true }
  func windowScene(_: UIWindowScene, performActionFor _: UIApplicationShortcutItem, completionHandler _: @escaping (Bool) -> Void) -> Bool { true }
}

@MainActor
func testSendable() {
  let a = FlutterBinaryCodec()
  let b = FlutterStringCodec()
  let c = FlutterJSONMessageCodec()
  let d = FlutterStandardReaderWriter()
  let e = FlutterStandardMessageCodec.sharedInstance()
  let f = FlutterMethodCall(methodName: "test", arguments: nil)
  let g = FlutterError(code: "test", message: nil, details: nil)
  let h = FlutterStandardTypedData(bytes: Data())
  let i = FlutterJSONMethodCodec.sharedInstance()
  let j = FlutterStandardMethodCodec.sharedInstance()

  Task { @Sendable in
    let _ = [a, b, c, d, e, f, g, h, i, j]
  }
}
