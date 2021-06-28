// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library canvaskit_initialization;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:ui/src/engine.dart' show isDesktop, kProfileMode, domRenderer;

import 'canvaskit_api.dart';
import 'fonts.dart';

/// A JavaScript entrypoint that allows developer to set rendering backend
/// at runtime before launching the application.
@JS('window.flutterWebRenderer')
external String? get requestedRendererType;

/// Whether to use CanvasKit as the rendering backend.
bool get useCanvasKit => flutterWebAutoDetect ? _detectRenderer() : _useSkia;

/// Returns true if CanvasKit is used.
///
/// Otherwise, returns false.
bool _detectRenderer() {
  if (requestedRendererType != null) {
    return requestedRendererType! == 'canvaskit';
  }
  // If requestedRendererType is not specified, use CanvasKit for desktop and
  // html for mobile.
  return isDesktop;
}

/// Auto detect which rendering backend to use.
///
/// Using flutter tools option "--web-render=auto" or not specifying one
/// would set the value to true. Otherwise, it would be false.
const bool flutterWebAutoDetect =
    bool.fromEnvironment('FLUTTER_WEB_AUTO_DETECT', defaultValue: true);

/// Enable the Skia-based rendering backend.
///
/// Using flutter tools option "--web-render=canvaskit" would set the value to
/// true.
/// Using flutter tools option "--web-render=html" would set the value to false.
const bool _useSkia =
    bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);

/// If set to true, forces CPU-only rendering (i.e. no WebGL).
///
/// This is mainly used for testing or for apps that want to ensure they
/// run on devices which don't support WebGL.
const bool canvasKitForceCpuOnly = bool.fromEnvironment(
    'FLUTTER_WEB_CANVASKIT_FORCE_CPU_ONLY',
    defaultValue: false);

/// The URL to use when downloading the CanvasKit script and associated wasm.
///
/// The expected directory structure nested under this URL is as follows:
///
///     /canvaskit.js              - the release build of CanvasKit JS API bindings
///     /canvaskit.wasm            - the release build of CanvasKit WASM module
///     /profiling/canvaskit.js    - the profile build of CanvasKit JS API bindings
///     /profiling/canvaskit.wasm  - the profile build of CanvasKit WASM module
///
/// The base URL can be overridden using the `FLUTTER_WEB_CANVASKIT_URL`
/// environment variable, which can be set in the Flutter tool using the
/// `--dart-define` option. The value must end with a `/`.
///
/// Example:
///
/// ```
/// flutter run \
///   -d chrome \
///   --web-renderer=canvaskit \
///   --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://example.com/custom-canvaskit-build/
/// ```
///
/// When CanvasKit pushes a new release to NPM, update this URL to reflect the
/// most recent version. For example, if CanvasKit releases version 0.34.0 to
/// NPM, update this URL to `https://unpkg.com/canvaskit-wasm@0.34.0/bin/`.
const String canvasKitBaseUrl = String.fromEnvironment(
  'FLUTTER_WEB_CANVASKIT_URL',
  defaultValue: 'https://unpkg.com/canvaskit-wasm@0.28.1/bin/',
);
final String canvasKitBuildUrl =
    canvasKitBaseUrl + (kProfileMode ? 'profiling/' : '');
final String canvasKitJavaScriptBindingsUrl =
    canvasKitBuildUrl + 'canvaskit.js';
String canvasKitWasmModuleUrl(String file) => canvasKitBuildUrl + file;

/// Initialize CanvasKit.
///
/// This calls `CanvasKitInit` and assigns the global [canvasKit] object.
Future<void> initializeCanvasKit() {
  final Completer<void> canvasKitCompleter = Completer<void>();
  if (windowFlutterCanvasKit != null) {
    canvasKit = windowFlutterCanvasKit!;
    canvasKitCompleter.complete();
  } else {
    domRenderer.canvasKitLoaded!.then((_) {
      final CanvasKitInitPromise canvasKitInitPromise =
          CanvasKitInit(CanvasKitInitOptions(
        locateFile: js.allowInterop(
            (String file, String unusedBase) => canvasKitWasmModuleUrl(file)),
      ));
      canvasKitInitPromise.then(js.allowInterop((CanvasKit ck) {
        canvasKit = ck;
        windowFlutterCanvasKit = canvasKit;
        canvasKitCompleter.complete();
      }));
    });
  }

  /// Add a Skia scene host.
  skiaSceneHost = html.Element.tag('flt-scene');
  domRenderer.renderScene(skiaSceneHost);
  return canvasKitCompleter.future;
}

/// The Skia font collection.
SkiaFontCollection get skiaFontCollection => _skiaFontCollection!;
SkiaFontCollection? _skiaFontCollection;

/// Initializes [skiaFontCollection].
void ensureSkiaFontCollectionInitialized() {
  _skiaFontCollection ??= SkiaFontCollection();
}

/// The scene host, where the root canvas and overlay canvases are added to.
html.Element? skiaSceneHost;
