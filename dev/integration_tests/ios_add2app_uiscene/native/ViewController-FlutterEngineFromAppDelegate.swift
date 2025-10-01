// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
    let flutterViewController =
        FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

    addChild(flutterViewController)
    flutterViewController.view.frame = self.view.frame
    self.view.addSubview(flutterViewController.view)
  }
}
