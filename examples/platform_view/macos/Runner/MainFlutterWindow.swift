// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

/**
 The main application window.

 Performs Flutter app initialization, and handles channel method calls over the
 `samples.flutter.io/platform_view` channel.
*/
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    RegisterMethodChannel(registry: flutterViewController)

    super.awakeFromNib()
  }

  func RegisterMethodChannel(registry: FlutterPluginRegistry) {
    let registrar = registry.registrar(forPlugin: "platform_view")
    let channel = FlutterMethodChannel(name: "samples.flutter.io/platform_view",
                                       binaryMessenger: registrar.messenger)
    channel.setMethodCallHandler({ (call, result) in
      if (call.method == "switchView") {
        let count = call.arguments as! Int
        let controller: NSViewController = PlatformViewController(
          withCount: count,
          onClose: { platformViewController in
            result(platformViewController.count)
          }
        )
        self.contentViewController?.presentAsSheet(controller)
      }
    })
  }
}
