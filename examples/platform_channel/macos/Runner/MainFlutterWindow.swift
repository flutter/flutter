// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, FlutterStreamHandler, PowerSourceStateChangeDelegate {
  private let powerSource = PowerSource()
  private let stateChangeSource = PowerSourceStateChangeHandler()
  private var eventSink: FlutterEventSink?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Register battery method channel.
    let registrar = flutterViewController.registrar(forPlugin: "BatteryLevel")
    let batteryChannel = FlutterMethodChannel(
      name: "samples.flutter.io/battery",
      binaryMessenger: registrar.messenger)
    batteryChannel.setMethodCallHandler({ [weak self] (call, result) in
      switch call.method {
      case "getBatteryLevel":
        if self?.powerSource.hasBattery() == false {
          result(FlutterError(
            code: "NO_BATTERY",
            message: "Device does not have a battery",
            details: nil))
          return
        }
        let level = self?.powerSource.getCurrentCapacity()
        if level == -1 {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Battery info unavailable",
              details: nil))
          return
        }
        result(level)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Register charging event channel.
    let chargingChannel = FlutterEventChannel(
      name: "samples.flutter.io/charging",
      binaryMessenger: registrar.messenger)
    chargingChannel.setStreamHandler(self)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
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
