// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A lazy container for an engine that will only dispense one engine.
///
/// This is used to hold an engine for plugin registration when the GeneratedPluginRegistrant is
/// called on a FlutterAppDelegate before the first FlutterViewController is set up. This is the
/// typical flow after the UISceneDelegate migration.
///
/// The launch engine is intended to work only with first FlutterViewController instantiated with a
/// NIB since that is the only FlutterEngine that registers plugins through the FlutterAppDelegate.
@objc(FlutterLaunchEngine)
public final class LaunchEngine: NSObject {
  private var didTakeEngine = false
  private var _engine: FlutterEngine?

  /// Accessor for the launch engine.
  ///
  /// Getting this may allocate an engine.
  @objc public var engine: FlutterEngine? {
    guard !didTakeEngine, _engine == nil else { return _engine }

    _engine = FlutterEngine(
      name: "io.flutter",
      project: FlutterDartProject(),
      allowHeadlessExecution: true,
      restorationEnabled: true
    )
    _engine?.run()
    return _engine
  }

  /// Take ownership of the launch engine.
  ///
  /// After this is called `self.engine` and `takeEngine` will always return nil.
  @objc public func takeEngine() -> FlutterEngine? {
    let result = _engine
    _engine = nil
    didTakeEngine = true
    return result
  }
}
