// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var eventReceiver: FlutterEventReceiver?;

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController;
    let batteryChannel = FlutterMethodChannel.init(name: "samples.flutter.io/battery",
                                                   binaryMessenger: controller);
    batteryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: FlutterResultReceiver) -> Void in
      if ("getBatteryLevel" == call.method) {
        self.receiveBatteryLevel(result: result);
      } else {
        result(FlutterMethodNotImplemented);
      }
      }
    );

    let chargingChannel = FlutterEventChannel.init(name: "samples.flutter.io/charging",
                                                   binaryMessenger: controller);
    chargingChannel.setStreamHandler(self);
    return true
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

  public func onListen(withArguments arguments: Any?,
                       eventReceiver: @escaping FlutterEventReceiver) -> FlutterError? {
    self.eventReceiver = eventReceiver;
    UIDevice.current.isBatteryMonitoringEnabled = true;
    self.sendBatteryStateEvent();
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onBatteryStateDidChange),
      name: NSNotification.Name.UIDeviceBatteryStateDidChange,
      object: nil)
    return nil;
  }

  @objc private func onBatteryStateDidChange(notification: NSNotification) {
    self.sendBatteryStateEvent();
  }

  private func sendBatteryStateEvent() {
    if (eventReceiver == nil) {
      return;
    }

    let state = UIDevice.current.batteryState;
    switch state {
    case UIDeviceBatteryState.full:
      eventReceiver!("charging");
      break;
    case UIDeviceBatteryState.charging:
      eventReceiver!("charging");
      break;
    case UIDeviceBatteryState.unplugged:
      eventReceiver!("discharging");
      break;
    default:
      eventReceiver!(FlutterError.init(code: "UNAVAILABLE",
                                       message: "Charging status unavailable",
                                       details: nil));
      break;
    }
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self);
    eventReceiver = nil;
    return nil;
  }
}
