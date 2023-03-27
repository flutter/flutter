// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

enum ChannelName {
  static let battery = "samples.flutter.io/battery"
  static let charging = "samples.flutter.io/charging"
}

enum BatteryState {
  static let charging = "charging"
  static let discharging = "discharging"
  static let unavailable = "UNAVAILABLE"
}

enum ErrorCode {
  static let noBattery = "NO_BATTERY"
  static let unavailable = "UNAVAILABLE"
}

class MainFlutterWindow: NSWindow {
  private let powerSource = PowerSource()
  private let stateChangeHandler = PowerSourceStateChangeHandler()
  private var eventSink: FlutterEventSink?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.displayIfNeeded()
    self.setFrame(windowFrame, display: true)

    // Register battery method channel.
    let registrar = flutterViewController.registrar(forPlugin: "BatteryLevel")
    let batteryChannel = FlutterMethodChannel(
      name: ChannelName.battery,
      binaryMessenger: registrar.messenger)
    batteryChannel.setMethodCallHandler { [powerSource = self.powerSource] (call, result) in
      switch call.method {
      case "getBatteryLevel":
        guard powerSource.hasBattery() else {
          result(
            FlutterError(
              code: ErrorCode.noBattery,
              message: "Device does not have a battery",
              details: nil))
          return
        }
        guard let level = powerSource.getCurrentCapacity() else {
          result(
            FlutterError(
              code: ErrorCode.unavailable,
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
      name: ChannelName.charging,
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
        sink(BatteryState.charging)
      case .battery:
        sink(BatteryState.discharging)
      case .unknown:
        sink(BatteryState.unavailable)
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
