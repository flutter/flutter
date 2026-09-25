// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import my_plugin

class ViewController: UIViewController {
  var flutterViewController: FlutterViewController?
  let label = UILabel()

  private var flutterEngine: FlutterEngine {
    return (UIApplication.shared.delegate as! AppDelegate).flutterEngine
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    // Create FlutterViewController with engine, but NEVER add it to the view hierarchy or as a child VC.
    flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

    setupNativeUI()
  }

  private func setupNativeUI() {
    let button = UIButton(type: .system)
    button.setTitle("Get Lifecycle Events", for: .normal)
    button.accessibilityIdentifier = "Get Lifecycle Events"
    button.frame = CGRect(x: 20, y: 100, width: 250, height: 50)
    button.addTarget(self, action: #selector(getLifecycleEvents), for: .touchUpInside)
    view.addSubview(button)

    label.frame = CGRect(x: 20, y: 160, width: 350, height: 400)
    label.numberOfLines = 0
    view.addSubview(label)
  }

  @objc private func getLifecycleEvents() {
    if let events = MyPlugin.instance?.events.joined(separator: "\n") {
      self.label.text = events
    }
  }
}
