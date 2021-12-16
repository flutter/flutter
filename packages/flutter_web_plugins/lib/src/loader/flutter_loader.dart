// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js.dart';

import 'js_interop/flutter_js_loader.dart';
import 'js_interop/promise_js.dart';

/// `true` if the new flutter loader configuration is present in the DOM.
final bool isFlutterJsLoaderConfigured = didLoadMainDartJs != null;

/// A class that controls the coarse lifecycle of a Flutter app.
// TODO(dit): Make this an abstract class and provide a Promise-based implementation
// (this one), and another one that doesn't wait for anything.
// Use a factory method to return the correct instance, so the user doesn't even
// have to worry about it.
//
//   ```dart
//     FlutterLoader loader = FlutterLoader.createLoader(initEngine, runApp, cleanApp);
//     // FlutterLoader may be a PromiseFlutterLoader or an AutomaticFlutterLoader (for example)
//     loader.notifyFlutterReady(); // Do things
//   ```
// TODO(dit): FlutterLoader might not be the best name for these classes though...
class FlutterLoader {
  /// Construct a FlutterLoader
  FlutterLoader({
    this.initEngine, this.runApp, this.cleanApp
  });

  // TODO(dit): Be more strict with the below typedefs, so we can add incoming params for each function.
  // TODO(dit): Make the below private members.

  /// A function to initialize the engine
  final Function? initEngine;
  /// A function to run the app
  final Function? runApp;
  /// A function to clear the app (optional)
  final Function? cleanApp;

  /// Notifies JS that Flutter is up and running.
  void notifyFlutterReady() {
    assert(isFlutterJsLoaderConfigured, '_flutter.loader is not correctly configured. Check your index.html!');
    didLoadMainDartJs!(_prepareEngineInitializer());
  }

  // Calls a function that may be null and/or async, and wraps it in a Future<Object?>
  Future<Object?> _safeCall(Function? fn) async {
    if (fn != null) {
      // ignore: avoid_dynamic_calls
      return Future<Object?>.value(fn());
    }
  }

  /// Creates an engineInitializer that runs our encapsulated initEngine function.
  FlutterEngineInitializer _prepareEngineInitializer() {
    // Return an object that has a initEngine method...
    return FlutterEngineInitializer(initializeEngine: allowInterop((InitializeEngineFnParameters? params) {
      // `params` coming from Javascript may be used to configure the engine intialization.
      // The internal `initEngine` function must accept those params, and then this
      // code needs to be slightly modified to pass them to the initEngine call below.
      return Promise<FlutterAppRunner>(allowInterop((PromiseResolver<FlutterAppRunner> resolve, PromiseRejecter _) async {
        await _safeCall(initEngine);
        // Resolve with an actual AppRunner object, created in a similar way
        // to how the FlutterEngineInitializer was created
        resolve(_prepareAppRunner());
      }));
    }));
  }

  /// Creates an appRunner that runs our encapsulated runApp function.
  FlutterAppRunner _prepareAppRunner() {
    return FlutterAppRunner(runApp: allowInterop((RunAppFnParameters? params) {
      // `params` coming from JS may be used to configure the run app method.
      return Promise<FlutterAppCleaner>(allowInterop((PromiseResolver<FlutterAppCleaner> resolve, PromiseRejecter _) async {
        await _safeCall(runApp);
        // Next step is an AppCleaner
        resolve(_prepareAppCleaner());
      }));
    }));
  }

  /// Clean the app that was injected above.
  FlutterAppCleaner _prepareAppCleaner() {
    return FlutterAppCleaner(cleanApp: allowInterop((CleanAppFnParameters? params) {
      return Promise<bool>(allowInterop((PromiseResolver<bool> resolve, PromiseRejecter _) async {
        await _safeCall(cleanApp);
        resolve(true);
      }));
    }));
  }
}
