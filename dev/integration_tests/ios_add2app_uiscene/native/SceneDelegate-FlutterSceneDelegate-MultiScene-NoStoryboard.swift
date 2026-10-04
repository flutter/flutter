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
    // Confirm the scene is a window scene in iOS or iPadOS.
    guard let windowScene = scene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)

    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    self.registerSceneLifeCycle(with: flutterEngine)
    let viewController = ViewController(engine: flutterEngine)

    window?.rootViewController = viewController
    window?.makeKeyAndVisible()
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
