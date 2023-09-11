// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'configuration.dart';
import 'js_interop/js_loader.dart';

/// The type of a function that initializes an engine (in Dart).
typedef InitEngineFn = Future<void> Function([JsFlutterConfiguration? params]);

/// A class that controls the coarse lifecycle of a Flutter app.
class AppBootstrap {
  /// Construct an AppBootstrap.
  AppBootstrap({required InitEngineFn initializeEngine, required Function runApp}) :
    _initializeEngine = initializeEngine, _runApp = runApp;

  // A function to initialize the engine.
  final InitEngineFn _initializeEngine;

  // A function to run the app.
  //
  // TODO(dit): Be more strict with the typedef of this function, so we can add
  // typed params to the function. (See InitEngineFn).
  final Function _runApp;

  /// Immediately bootstraps the app.
  ///
  /// This calls `initEngine` and `runApp` in succession.
  Future<void> autoStart() async {
    await _initializeEngine();
    await _runApp();
  }

  /// Creates an engine initializer that runs our encapsulated initEngine function.
  FlutterEngineInitializer prepareEngineInitializer() {
    return FlutterEngineInitializer(
      // This is a convenience method that lets the programmer call "autoStart"
      // from JavaScript immediately after the main.dart.js has loaded.
      // Returns a promise that resolves to the Flutter app that was started.
      autoStart: () async {
        await autoStart();
        // Return the App that was just started
        return _prepareFlutterApp();
      },
      // Calls [_initEngine], and returns a JS Promise that resolves to an
      // app runner object.
      initializeEngine: ([JsFlutterConfiguration? configuration]) async {
        await _initializeEngine(configuration);
        return _prepareAppRunner();
      }
    );
  }

  /// Creates an appRunner that runs our encapsulated runApp function.
  FlutterAppRunner _prepareAppRunner() {
    return FlutterAppRunner(runApp: ([RunAppFnParameters? params]) async {
      await _runApp();
      return _prepareFlutterApp();
    });
  }

  /// Represents the App that was just started, and its JS API.
  FlutterApp _prepareFlutterApp() {
    return FlutterApp();
  }
}
