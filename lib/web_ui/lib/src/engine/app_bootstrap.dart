// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';

import 'js_interop/js_loader.dart';
import 'js_interop/js_promise.dart';

/// A class that controls the coarse lifecycle of a Flutter app.
class AppBootstrap {
  /// Construct a FlutterLoader
  AppBootstrap({required Function initEngine, required Function runApp}) :
    _initEngine = initEngine, _runApp = runApp;

  // TODO(dit): Be more strict with the below typedefs, so we can add incoming params for each function.

  // A function to initialize the engine
  final Function _initEngine;

  // A function to run the app
  final Function _runApp;

  /// Immediately bootstraps the app.
  ///
  /// This calls `initEngine` and `runApp` in succession.
  Future<void> autoStart() async {
    await _initEngine();
    await _runApp();
  }

  /// Creates an engine initializer that runs our encapsulated initEngine function.
  FlutterEngineInitializer prepareEngineInitializer() {
    return FlutterEngineInitializer(
      // This is a convenience method that lets the programmer call "autoStart"
      // from JavaScript immediately after the main.dart.js has loaded.
      // Returns a promise that resolves to the Flutter app that was started.
      autoStart: allowInterop(() {
        return Promise<FlutterApp>(allowInterop((
          PromiseResolver<FlutterApp> resolve,
          PromiseRejecter _,
        ) async {
          await autoStart();
          // Return the App that was just started
          resolve(_prepareFlutterApp());
        }));
      }),
      // Calls [_initEngine], and returns a JS Promise that resolves to an
      // app runner object.
      initializeEngine: allowInterop(([InitializeEngineFnParameters? params]) {
        // `params` coming from Javascript may be used to configure the engine intialization.
        // The internal `initEngine` function must accept those params, and then this
        // code needs to be slightly modified to pass them to the initEngine call below.
        return Promise<FlutterAppRunner>(allowInterop((
          PromiseResolver<FlutterAppRunner> resolve,
          PromiseRejecter _,
        ) async {
          await _initEngine();
          // Return an app runner object
          resolve(_prepareAppRunner());
        }));
      }),
    );
  }

  /// Creates an appRunner that runs our encapsulated runApp function.
  FlutterAppRunner _prepareAppRunner() {
    return FlutterAppRunner(runApp: allowInterop(([RunAppFnParameters? params]) {
      // `params` coming from JS may be used to configure the run app method.
      return Promise<FlutterApp>(allowInterop((
        PromiseResolver<FlutterApp> resolve,
        PromiseRejecter _,
      ) async {
        await _runApp();
        // Return the App that was just started
        resolve(_prepareFlutterApp());
      }));
    }));
  }

  /// Represents the App that was just started, and its JS API.
  FlutterApp _prepareFlutterApp() {
    return FlutterApp();
  }
}
