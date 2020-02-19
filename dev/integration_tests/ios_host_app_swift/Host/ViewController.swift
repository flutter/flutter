// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter
import FlutterPluginRegistrant

class ViewController: UIViewController {
  var flutterEngine : FlutterEngine?;

  // Boiler-plate add-to-app demo. Not integration tested anywhere.
  override func viewDidLoad() {
    super.viewDidLoad()
    let button = UIButton(type:UIButton.ButtonType.custom)
    button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
    button.setTitle("Press me", for: UIControl.State.normal)
    button.frame = CGRect(x: 80.0, y: 210.0, width: 160.0, height: 40.0)
    button.backgroundColor = UIColor.blue
    self.view.addSubview(button)
    self.flutterEngine = FlutterEngine(name: "io.flutter", project: nil);
  }

  @objc func handleButtonAction() {
    if let flutterEngine = flutterEngine as? FlutterEngine {
      GeneratedPluginRegistrant.register(with: flutterEngine);

      let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil);
      self.present(flutterViewController, animated: false, completion: nil)
    }
  }
}
