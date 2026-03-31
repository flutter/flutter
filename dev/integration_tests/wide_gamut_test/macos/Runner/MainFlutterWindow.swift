// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@objc protocol PrivateFlutterView {
  func setEnableWideGamut(_ enabled: Bool)
}

class WideGamutViewController: FlutterViewController {

  // Override the method in the view controller to force wide-gamut support.
  @objc(updateWideGamutForScreen)
  func updateWideGamutForScreen() {
    if let flutterView = self.view as? PrivateFlutterView {
      flutterView.setEnableWideGamut(true) // Always force true
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
    let flutterViewController = WideGamutViewController()

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
