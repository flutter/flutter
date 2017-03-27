// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    private var events: FlutterEventReceiver?;
    
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let controller = window.rootViewController as! FlutterViewController;
        let batteryChannel = FlutterMethodChannel.init(
            name: "io.flutter.samples/battery",
            binaryMessenger: controller);
        batteryChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result:FlutterResultReceiver) -> Void in
            if "getBatteryLevel" == call.method {
                self.getBatteryLevel(result: result);
            } else {
                result(FlutterMethodNotImplemented);
            }
        });
        let chargingChannel = FlutterEventChannel.init(
            name: "io.flutter.samples/charging",
            binaryMessenger:controller);
        chargingChannel.setStreamHandler(self);
        return true;
    }
    
    private func getBatteryLevel(result: FlutterResultReceiver) {
        let device = UIDevice.current;
        device.isBatteryMonitoringEnabled = true;
        if device.batteryState == UIDeviceBatteryState.unknown {
            result(FlutterError.init(
                code: "UNAVAILABLE",
                message: "Battery info unavailable",
                details:nil));
        } else {
            result(Int(device.batteryLevel * 100));
        }
    }
    
    public func onListen(withArguments arguments: Any?,
                         eventReceiver: @escaping FlutterEventReceiver) -> FlutterError? {
        events = eventReceiver;
        UIDevice.current.isBatteryMonitoringEnabled = true;
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBatteryStateDidChange),
            name: NSNotification.Name.UIDeviceBatteryStateDidChange,
            object: nil);
        return nil;
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self);
        events = nil;
        return nil;
    }
    
    @objc private func onBatteryStateDidChange(notification: NSNotification) {
        if (events == nil) {
            return;
        }
        let state = UIDevice.current.batteryState;
        switch (state) {
        case UIDeviceBatteryState.charging:
            events!("charging");
        case UIDeviceBatteryState.full:
            events!("charging");
        case UIDeviceBatteryState.unplugged:
            events!("discharging");
        case UIDeviceBatteryState.unknown:
            events!(FlutterError.init(
                code: "UNKNOWN",
                message: "Battery state is unknown",
                details:nil));
        }
    }
}
