// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    NSLog("MainFlutterWindow.awakeFromNit: creating view controller...");
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    NSLog("MainFlutterWindow.awakeFromNit: registering plugins...");

    RegisterGeneratedPlugins(registry: flutterViewController)
    NSLog("MainFlutterWindow.awakeFromNit: registered plugins");

    super.awakeFromNib()
    NSLog("MainFlutterWindow.awakeFromNit: done");
  }
}
