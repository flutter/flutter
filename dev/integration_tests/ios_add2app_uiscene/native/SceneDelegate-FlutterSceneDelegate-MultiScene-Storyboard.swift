// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import FlutterPluginRegistrant
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  let flutterEngine = FlutterEngine(name: "my flutter engine")

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    self.registerSceneLifeCycle(with: flutterEngine)

    if let viewController = window?.rootViewController as? ViewController {
      viewController.flutterEngine = flutterEngine
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
