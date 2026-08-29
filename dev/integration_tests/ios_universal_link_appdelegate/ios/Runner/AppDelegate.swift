// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    LifecycleDetectorPlugin.register(
      with: self.registrar(forPlugin: "LifecycleDetectorPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

public class LifecycleDetectorPlugin: NSObject, FlutterPlugin {
  static var shared: LifecycleDetectorPlugin?
  static var events = [String]()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "lifecycle_detector", binaryMessenger: registrar.messenger())
    let instance = LifecycleDetectorPlugin()
    shared = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getEvents" {
      result(LifecycleDetectorPlugin.events)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if let activityDict = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any],
      let activity = activityDict["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity,
      let url = activity.webpageURL
    {
      let event = "applicationContinueUserActivity: \(url.absoluteString)"
      if !LifecycleDetectorPlugin.events.contains(event) {
        LifecycleDetectorPlugin.events.append(event)
      }
    }
    if let url = launchOptions?[.url] as? URL {
      let event = "applicationOpenURL: \(url.absoluteString)"
      if !LifecycleDetectorPlugin.events.contains(event) {
        LifecycleDetectorPlugin.events.append(event)
      }
    }
    return false
  }

  @objc(application:continueUserActivity:restorationHandler:)
  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      let event = "applicationContinueUserActivity: \(url.absoluteString)"
      if !LifecycleDetectorPlugin.events.contains(event) {
        LifecycleDetectorPlugin.events.append(event)
      }
    }
    return false
  }

  public func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let event = "applicationOpenURL: \(url.absoluteString)"
    if !LifecycleDetectorPlugin.events.contains(event) {
      LifecycleDetectorPlugin.events.append(event)
    }
    return false
  }
}
