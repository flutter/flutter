// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Since the plugin lives in the app itself, registration isn't auto-generated into
    // RegisterGeneratedPlugins in GeneratedPluginRegistrant.swift, so we register the plugin
    // manually.
    BatteryLevelPlugin.register(with: flutterViewController.registrar(forPlugin: "BatteryLevel"))

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
