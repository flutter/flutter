// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?;

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with: self);
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController;
    let batteryChannel = FlutterMethodChannel.init(name: "samples.flutter.io/battery",
                                                   binaryMessenger: controller);
    batteryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: FlutterResult) -> Void in
      if ("getBatteryLevel" == call.method) {
        self.receiveBatteryLevel(result: result);
      } else {
        result(FlutterMethodNotImplemented);
      }
    });

    let chargingChannel = FlutterEventChannel.init(name: "samples.flutter.io/charging",
                                                   binaryMessenger: controller);
    chargingChannel.setStreamHandler(self);
    return super.application(application, didFinishLaunchingWithOptions: launchOptions);
  }

  private func receiveBatteryLevel(result: FlutterResult) {
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
                       eventSink: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = eventSink;
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
    if (eventSink == nil) {
      return;
    }

    let state = UIDevice.current.batteryState;
    switch state {
    case UIDeviceBatteryState.full:
      eventSink!("charging");
      break;
    case UIDeviceBatteryState.charging:
      eventSink!("charging");
      break;
    case UIDeviceBatteryState.unplugged:
      eventSink!("discharging");
      break;
    default:
      eventSink!(FlutterError.init(code: "UNAVAILABLE",
                                   message: "Charging status unavailable",
                                   details: nil));
      break;
    }
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self);
    eventSink = nil;
    return nil;
  }
}
