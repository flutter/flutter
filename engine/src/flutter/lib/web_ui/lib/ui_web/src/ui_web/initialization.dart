// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'asset_manager.dart';

/// Bootstraps the Flutter Web engine and app.
///
/// If the app uses plugins, then the [registerPlugins] callback can be provided
/// to register those plugins. This is done typically by calling
/// `registerPlugins` from the auto-generated `web_plugin_registrant.dart` file.
///
/// The [runApp] callback is invoked to run the app after the engine is fully
/// initialized.
///
/// For more information, see what the `flutter_tools` does in the entrypoint
/// that it generates around the app's main method:
///
/// * https://github.com/flutter/flutter/blob/95be76ab7e3dca2def54454313e97f94f4ac4582/packages/flutter_tools/lib/src/web/file_generators/main_dart.dart#L14-L43
///
/// By default, engine initialization and app startup occur immediately and back
/// to back. They can be programmatically controlled by setting
/// `FlutterLoader.didCreateEngineInitializer`. For more information, see how
/// `flutter.js` does it:
///
/// * https://github.com/flutter/flutter/blob/95be76ab7e3dca2def54454313e97f94f4ac4582/packages/flutter_tools/lib/src/web/file_generators/js/flutter.js
Future<void> bootstrapEngine({ui.VoidCallback? registerPlugins, ui.VoidCallback? runApp}) async {
  // Create the object that knows how to bootstrap an app from JS and Dart.
  final bootstrap = AppBootstrap(
    initializeEngine: ([JsFlutterConfiguration? configuration]) async {
      await initializeEngineServices(jsConfiguration: configuration);
    },
    runApp: () async {
      if (registerPlugins != null) {
        registerPlugins();
      }
      await initializeEngineUi();
      if (runApp != null) {
        runApp();
      }
    },
  );

  final FlutterLoader? loader = flutter?.loader;
  if (loader == null || loader.isAutoStart) {
    // The user does not want control of the app, bootstrap immediately.
    await bootstrap.autoStart();
  } else {
    // Yield control of the bootstrap procedure to the user.
    loader.didCreateEngineInitializer(bootstrap.prepareEngineInitializer());
  }
}

/// Initializes the [AssetManager] used by the Flutter Web Engine.
///
/// This may be used by external plugins or tools to initialize the [assetManager]
/// during early plugin registration prior to full engine initialization.
///
/// If [manager] is omitted, a default [AssetManager] is created and registered.
void initializeAssetManager([AssetManager? manager]) {
  setAssetManager(manager ?? AssetManager());
}

/// Bootstraps the non-UI services of the Flutter Web engine.
///
/// This initializes engine-level background services, including platform channels,
/// asset bundle resolution, and system event bindings, without creating rendering
/// surfaces, WebGL contexts, or DOM host structures.
///
/// Use this function along with [bootstrapEngineUi] when taking manual control over
/// engine initialization from a Dart web application (e.g. when embedding Flutter
/// inside an existing web page or framework) instead of the default [bootstrapEngine]
/// and `flutter_bootstrap.js`.
///
/// A call to [bootstrapEngineServices] must be followed by a call to
/// [bootstrapEngineUi] before any Flutter views can be rendered.
///
/// The [assetManager] can be explicitly supplied; if omitted, the existing
/// [ui_web.assetManager] is used.
///
/// The [jsConfiguration] object corresponds to the JavaScript configuration passed to
/// the Flutter loader. It must only contain valid configuration properties
/// documented at https://docs.flutter.dev/platform-integration/web/initialization#customize-the-flutter-loader,
/// such as `multiViewEnabled`, `renderer`, or `assetBase`.
Future<void> bootstrapEngineServices({
  AssetManager? assetManager,
  JSObject? jsConfiguration,
}) async {
  await initializeEngineServices(
    assetManager: assetManager,
    jsConfiguration: jsConfiguration as JsFlutterConfiguration?,
  );
}

/// Bootstraps the UI services of the Flutter Web engine.
///
/// Initializes the rendering engine (e.g. CanvasKit or Skwasm), window and display
/// bindings, and view management.
///
/// Must only be used when manually initializing the engine from Dart, and
/// must be called after [bootstrapEngineServices].
///
/// Once this future completes, the engine is ready to accept views created via
/// [FlutterViewManagerProxy.addView] and render widget trees.
Future<void> bootstrapEngineUi() async {
  await initializeEngineUi();
}
