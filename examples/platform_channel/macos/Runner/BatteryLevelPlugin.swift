// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS
import Foundation

class BatteryLevelPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  PowerSourceStateChangeDelegate
{
  private let powerSource = PowerSource()
  private let stateChangeSource = PowerSourceStateChangeHandler()
  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let batteryChannel = FlutterMethodChannel(
      name: "samples.flutter.io/battery",
      binaryMessenger: registrar.messenger)
    let instance = BatteryLevelPlugin()
    registrar.addMethodCallDelegate(instance, channel: batteryChannel)

    let chargingChannel = FlutterEventChannel(
      name: "samples.flutter.io/charging",
      binaryMessenger: registrar.messenger)
    chargingChannel.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBatteryLevel":
      let level = powerSource.getCurrentCapacity()
      if level == -1 {
        result(
          FlutterError(
            code: "UNAVAILABLE",
            message: "Battery info unavailable",
            details: nil))
      }
      result(level)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    self.emitPowerStatusEvent()
    self.stateChangeSource.delegate = self
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.stateChangeSource.delegate = nil
    self.eventSink = nil
    return nil
  }

  func onPowerSourceStateChanged() {
    self.emitPowerStatusEvent()
  }

  func emitPowerStatusEvent() {
    if let sink = self.eventSink {
      switch self.powerSource.getPowerState() {
      case .ac:
        sink("charging")
      case .battery:
        sink("discharging")
      case .unknown:
        sink("UNAVAILABLE")
      }
    }
  }
}
