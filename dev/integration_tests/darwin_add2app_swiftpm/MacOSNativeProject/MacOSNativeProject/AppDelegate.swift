// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS
import FlutterPluginRegistrant

@main
class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(
    name: "my flutter engine",
    project: nil
  )

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    flutterEngine.run(withEntrypoint: nil)
    RegisterGeneratedPlugins(registry: self.flutterEngine)
  }
}
