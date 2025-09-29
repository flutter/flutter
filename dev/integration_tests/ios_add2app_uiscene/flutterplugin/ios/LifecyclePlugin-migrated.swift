// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

public class MyPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  var events = [String]()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "my_plugin",
      binaryMessenger: registrar.messenger()
    )
    let instance = MyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    registrar.addSceneDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  {
    switch call.method {
    case "getLifecycleEvents":
      result(events.joined(separator: "\n"))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Application Events

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
  ) -> Bool {
    events.append("applicationDidFinishLaunchingWithOptions")
    return true
  }

  public func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
  ) -> Bool {
    events.append("applicationWillFinishLaunchingWithOptions")
    return true
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    events.append("applicationDidBecomeActive")
  }

  public func applicationWillResignActive(_ application: UIApplication) {
    events.append("applicationWillResignActive")
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
    events.append("applicationDidEnterBackground")
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
    events.append("applicationWillEnterForeground")
  }

  public func applicationWillTerminate(_ application: UIApplication) {
    events.append("applicationWillTerminate")
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    events.append("applicationOpenURL")
    return true
  }

  public func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool {
    events.append("applicationPerformActionFor")
    return true
  }

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void
  ) -> Bool {
    events.append("applicationContinueUserActivity")
    return true
  }

  // MARK: - Scene Events

  public func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    events.append("sceneWillConnect")
    return true
  }

  public func sceneDidDisconnect(_ scene: UIScene) {
    events.append("sceneDidDisconnect")
  }

  public func sceneWillEnterForeground(_ scene: UIScene) {
    events.append("sceneWillEnterForeground")
  }

  public func sceneDidBecomeActive(_ scene: UIScene) {
    events.append("sceneDidBecomeActive")
  }

  public func sceneWillResignActive(_ scene: UIScene) {
    events.append("sceneWillResignActive")
  }

  public func sceneDidEnterBackground(_ scene: UIScene) {
    events.append("sceneDidEnterBackground")
  }

  public func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) -> Bool {
    events.append("sceneOpenURLContexts")
    return true
  }

  public func scene(_ scene: UIScene, continue userActivity: NSUserActivity)
    -> Bool
  {
    events.append("sceneContinueUserActivity")
    return true
  }

  public func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool {
    events.append("scenePerformActionFor")
    return true
  }
}
