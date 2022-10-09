// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

/**
The window that is automatically generated when `flutter create --target=macos`
on a project. `MainFlutterWindow` uses a FlutterViewController as it's content
view controller by default.
*/
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let windowFrame = self.frame
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: Bundle.main)
    // `flutter create --target=macos` uses this class (`self`) as an entrypoint
    // for drawing on a surface. The line below intercepts that and uses
    // the storyboard from `Main.storyboard`.
    self.contentViewController = storyboard.instantiateController(withIdentifier: "MainViewController") as! NSViewController
    self.setFrame(windowFrame, display: true)

    super.awakeFromNib()
  }
}
