// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let powerSource = PowerSource()
  private let stateChangeHandler = PowerSourceStateChangeHandler()
  private var eventSink: FlutterEventSink?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.displayIfNeeded()
    self.setFrame(windowFrame, display: true)

    // Register battery method channel.
    let registrar = flutterViewController.registrar(forPlugin: "BatteryLevel")
    let batteryChannel = FlutterMethodChannel(
      name: "samples.flutter.io/battery",
      binaryMessenger: registrar.messenger)
    batteryChannel.setMethodCallHandler { [powerSource = self.powerSource] (call, result) in
      switch call.method {
      case "getBatteryLevel":
        guard powerSource.hasBattery() else {
          result(
            FlutterError(
              code: "NO_BATTERY",
              message: "Device does not have a battery",
              details: nil))
          return
        }
        guard let level = powerSource.getCurrentCapacity() else {
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
    }

    // Register charging event channel.
    let chargingChannel = FlutterEventChannel(
      name: "samples.flutter.io/charging",
      binaryMessenger: registrar.messenger)
    chargingChannel.setStreamHandler(self)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Emit a power status event to the registered event sink.
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

extension MainFlutterWindow: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    self.emitPowerStatusEvent()
    self.stateChangeHandler.delegate = self
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.stateChangeHandler.delegate = nil
    self.eventSink = nil
    return nil
  }
}

extension MainFlutterWindow: PowerSourceStateChangeDelegate {
  func didChangePowerSourceState() {
    self.emitPowerStatusEvent()
  }
}
