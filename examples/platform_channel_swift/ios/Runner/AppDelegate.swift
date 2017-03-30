// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController;
      let batteryChannel = FlutterMethodChannel.init(name: "samples.flutter.io/battery",
                                                     binaryMessenger: controller);
      batteryChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: FlutterResultReceiver) -> Void in
        if ("getBatteryLevel" == call.method) {
          receiveBatteryLevel(result: result);
        } else {
          result(FlutterMethodNotImplemented);
        }
      }
    );
    return true
  }
}

private func receiveBatteryLevel(result: FlutterResultReceiver) {
  let device = UIDevice.current;
  device.isBatteryMonitoringEnabled = true;
  if (device.batteryState == UIDeviceBatteryState.unknown) {
    result(FlutterError.init(code: "UNAVAILABLE",
                             message: "Battery info unavailable",
                             details: nil));
  } else {
    result(Int(device.batteryLevel * 100));
  }
}
