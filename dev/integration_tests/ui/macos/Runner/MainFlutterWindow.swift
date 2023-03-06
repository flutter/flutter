// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

extension NSWindow {
  var titlebarHeight: CGFloat {
    frame.height - contentRect(forFrameRect: frame).height
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterMethodChannel(registry: flutterViewController)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

    func RegisterMethodChannel(registry: FlutterPluginRegistry) {
    let registrar = registry.registrar(forPlugin: "resize")
    let channel = FlutterMethodChannel(name: "samples.flutter.dev/resize",
                                       binaryMessenger: registrar.messenger)
    channel.setMethodCallHandler({ (call, result) in
      if call.method == "resize" {
        if let args = call.arguments as? Dictionary<String, Any>,
          let width = args["width"] as? Double,
          var height = args["height"] as? Double {
          height += self.titlebarHeight
          let currentFrame: NSRect = self.frame
          let nextFrame: NSRect = NSMakeRect(
            currentFrame.minX - (width - currentFrame.width) / 2,
            currentFrame.minY - (height - currentFrame.height) / 2,
            width,
            height
          )
          self.setFrame(nextFrame, display: true, animate: false)
          result(true)
        } else {
          result(FlutterError.init(code: "bad args", message: nil, details: nil))
        }
      }
    })
  }
}
