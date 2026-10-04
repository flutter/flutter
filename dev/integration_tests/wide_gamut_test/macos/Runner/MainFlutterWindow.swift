// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS
import Foundation

class WideGamutViewController: FlutterViewController {

  // This intercepts the private engine method called during window moves/resizes.
  // By overriding it, we stop the engine from checking the screen and disabling wide-gamut.
  @objc(updateWideGamutForScreen)
  func updateWideGamutForScreen() {
    let flutterView = self.view
    let mySelector = Selector("setEnableWideGamut:")

    // 1. Check if the object actually has this method
    if flutterView.responds(to: mySelector) {
      // 2. Call the method using reflection.
      flutterView.perform(mySelector, with: true)
    }
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    // Force the surface to 10-bit during the initial view loading sequence.
    self.updateWideGamutForScreen()
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Instantiate our custom subclass instead of the standard FlutterViewController.
    let flutterViewController = WideGamutViewController()

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
