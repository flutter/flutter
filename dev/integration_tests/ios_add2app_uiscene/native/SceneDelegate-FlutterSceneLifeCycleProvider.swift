// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate,
  FlutterSceneLifeCycleProvider
{
  let sceneLifeCycleDelegate = FlutterPluginSceneLifeCycleDelegate()

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard (scene as? UIWindowScene) != nil else { return }

    sceneLifeCycleDelegate.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    sceneLifeCycleDelegate.sceneDidDisconnect(scene)
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    sceneLifeCycleDelegate.sceneWillEnterForeground(scene)
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    sceneLifeCycleDelegate.sceneDidBecomeActive(scene)
  }

  func sceneWillResignActive(_ scene: UIScene) {
    sceneLifeCycleDelegate.sceneWillResignActive(scene)
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    sceneLifeCycleDelegate.sceneDidEnterBackground(scene)
  }

  func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    sceneLifeCycleDelegate.scene(scene, openURLContexts: URLContexts)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    sceneLifeCycleDelegate.scene(scene, continue: userActivity)
  }

  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    sceneLifeCycleDelegate.windowScene(
      windowScene,
      performActionFor: shortcutItem,
      completionHandler: completionHandler
    )
  }
}
