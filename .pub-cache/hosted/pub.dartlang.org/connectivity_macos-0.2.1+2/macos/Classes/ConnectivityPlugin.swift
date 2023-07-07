// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import CoreWLAN
import FlutterMacOS
import Reachability
import SystemConfiguration.CaptiveNetwork

public class ConnectivityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  var reach: Reachability?
  var eventSink: FlutterEventSink?
  var cwinterface: CWInterface?

  public override init() {
    cwinterface = CWWiFiClient.shared().interface()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/connectivity",
      binaryMessenger: registrar.messenger)

    let streamChannel = FlutterEventChannel(
      name: "plugins.flutter.io/connectivity_status",
      binaryMessenger: registrar.messenger)

    let instance = ConnectivityPlugin()
    streamChannel.setStreamHandler(instance)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "check":
      result(statusFromReachability(reachability: Reachability.forInternetConnection()))
    case "wifiName":
      result(cwinterface?.ssid())
    case "wifiBSSID":
      result(cwinterface?.bssid())
    case "wifiIPAddress":
      result(getWifiIP())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Returns a string describing connection type
  ///
  /// - Parameters:
  ///   - reachability: an instance of reachability
  /// - Returns: connection type string
  private func statusFromReachability(reachability: Reachability?) -> String {
    // checks any non-WWAN connection
    if reachability?.isReachableViaWiFi() ?? false {
      return "wifi"
    }

    return "none"
  }

  public func onListen(
    withArguments _: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    reach = Reachability.forInternetConnection()
    eventSink = events

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reachabilityChanged),
      name: NSNotification.Name.reachabilityChanged,
      object: reach)

    reach?.startNotifier()

    return nil
  }

  @objc private func reachabilityChanged(notification: NSNotification) {
    let reach = notification.object
    let reachability = statusFromReachability(reachability: reach as? Reachability)
    eventSink?(reachability)
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    reach?.stopNotifier()
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
