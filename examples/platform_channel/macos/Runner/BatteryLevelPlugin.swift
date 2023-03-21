// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import FlutterMacOS

class BatteryLevelPlugin : NSObject, FlutterPlugin, FlutterStreamHandler {
  private let powerSource = PowerSource()
  private var eventSink: FlutterEventSink?
  private var runLoopSource: CFRunLoopSource?

  static func register(with registrar: FlutterPluginRegistrar) {
    let batteryChannel = FlutterMethodChannel(name: "samples.flutter.io/battery",
                                              binaryMessenger: registrar.messenger)
    let instance = BatteryLevelPlugin()
    registrar.addMethodCallDelegate(instance, channel: batteryChannel)

    let chargingChannel = FlutterEventChannel(name: "samples.flutter.io/charging",
                                              binaryMessenger: registrar.messenger)
    chargingChannel.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBatteryLevel":
      let level = powerSource.getCurrentCapacity()
      if level == -1 {
        result(FlutterError(code: "UNAVAILABLE",
                            message: "Battery info unavailable",
                            details: nil))
      }
      result(level)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events

    // Emit an initial power status event.
    self.emitPowerStatusEvent()

    let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    self.runLoopSource = IOPSNotificationCreateRunLoopSource({ (context: UnsafeMutableRawPointer?) in
      let weakSelf = Unmanaged<BatteryLevelPlugin>.fromOpaque(UnsafeRawPointer(context!)).takeUnretainedValue()
      weakSelf.emitPowerStatusEvent()
    }, context).takeRetainedValue()
    CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .defaultMode)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    self.eventSink = nil
    return nil
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
