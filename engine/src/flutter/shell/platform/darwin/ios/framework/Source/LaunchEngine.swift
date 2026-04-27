// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A lazy container for a `FlutterEngine` instance used during application startup.
///
/// This class manages the lifecycle of a single FlutterEngine used primarily for plugin
/// registration before a `FlutterViewController` is presented.
///
/// Calling the `acquireEngine` method lazily creates and starts the engine. Ownership of the
/// engine can be transferred to a consumer by calling `takeEngine()`. Once the engine has been
/// taken, the container remains empty; subsequent calls to `acquireEngine` or `takeEngine` will
/// return nil.
///
/// This class is an internal compatibility measure for applications using `FlutterAppDelegate`
/// while migrating to `UISceneDelegate`. Apple introduced `UISceneDelegate` in iOS 13, moving UI
/// setup (and thus `FlutterViewController` creation) out of
/// `application:didFinishLaunching:withOptions:` and into the scene connection lifecycle.
///
/// Historically, Flutter plugins registered in
/// `[UIApplicationDelegate application:didFinishLaunching:withOptions:]`. In a scene-based app, no
/// FlutterViewController has yet been presented at that point and thus no engine would be available
/// for registration. `LaunchEngine` bridges this gap by providing a lazy engine early, which the
/// `FlutterViewController` adopts later.
///
/// For new application code, application developers should consider conforming to
/// `FlutterImplicitEngineDelegate` and implementing `didInitializeImplicitFlutterEngine` instead of
/// relying on `FlutterAppDelegate`'s automatic registration.
@objc(FlutterLaunchEngine)
public final class LaunchEngine: NSObject {

  /// The lifecycle state of the contained engine.
  private enum State {
    /// The initial state where the engine has not been instantiated yet.
    case uninitialized

    /// The engine has been instantiated by calling `acquireEngine` and is cached.
    case created(FlutterEngine)

    /// The engine has been transferred to a consumer via `takeEngine`, leaving the container empty.
    case taken
  }

  private var state = State.uninitialized

  /// Acquires the cached engine.
  ///
  /// In cases where `takeEngine` has not yet been called, this will lazily allocate and return an
  /// engine.
  @objc public func acquireEngine() -> FlutterEngine? {
    switch state {
    case .uninitialized:
      let newEngine = FlutterEngine(
        name: "io.flutter",
        project: FlutterDartProject(),
        allowHeadlessExecution: true,
        restorationEnabled: true
      )
      newEngine.run()
      state = .created(newEngine)
      return newEngine

    case .created(let existingEngine):
      return existingEngine

    case .taken:
      return nil
    }
  }

  /// Take ownership of the launch engine.
  ///
  /// After this is called `acquireEngine` and `takeEngine` will always return nil.
  @objc public func takeEngine() -> FlutterEngine? {
    let result: FlutterEngine?
    switch state {
    case .created(let engine):
      result = engine
    case .uninitialized, .taken:
      result = nil
    }
    state = .taken
    return result
  }
}
