// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

class ViewController: UIViewController {
  let flutterEngine: FlutterEngine

  init(engine: FlutterEngine) {
    self.flutterEngine = engine
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let flutterViewController =
        FlutterViewController(engine: self.flutterEngine, nibName: nil, bundle: nil)
    addChild(flutterViewController)
    flutterViewController.view.frame = self.view.frame
    self.view.addSubview(flutterViewController.view)
  }
}
