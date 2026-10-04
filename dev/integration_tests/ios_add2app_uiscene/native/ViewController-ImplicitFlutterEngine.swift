// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let flutterViewController = FlutterViewController(
      project: nil,
      nibName: nil,
      bundle: nil
    )
    addChild(flutterViewController)
    flutterViewController.view.frame = self.view.frame
    self.view.addSubview(flutterViewController.view)
  }
}
