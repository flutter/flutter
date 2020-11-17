// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A JavaScript entrypoint that allows developer to set rendering backend
/// at runtime before launching the application.
@JS('window.flutterWebRenderer')
external String? get requestedRendererType;

/// Whether to use CanvasKit as the rendering backend.
bool get useCanvasKit =>
    _autoDetect ? _detectRenderer() : _useSkia;

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
/// Using flutter tools option "--web-render=auto" would set the value to true.
/// Otherwise, it would be false.
const bool _autoDetect =
    bool.fromEnvironment('FLUTTER_WEB_AUTO_DETECT', defaultValue: false);

/// Enable the Skia-based rendering backend.
///
/// Using flutter tools option "--web-render=canvaskit" would set the value to
/// true.
/// Using flutter tools option "--web-render=html" would set the value to false.
const bool _useSkia =
    bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);

// If set to true, forces CPU-only rendering (i.e. no WebGL).
const bool canvasKitForceCpuOnly =
    bool.fromEnvironment('FLUTTER_WEB_CANVASKIT_FORCE_CPU_ONLY', defaultValue: false);

/// The URL to use when downloading the CanvasKit script and associated wasm.
///
/// When CanvasKit pushes a new release to NPM, update this URL to reflect the
/// most recent version. For example, if CanvasKit releases version 0.34.0 to
/// NPM, update this URL to `https://unpkg.com/canvaskit-wasm@0.34.0/bin/`.
const String canvasKitBaseUrl = String.fromEnvironment(
  'FLUTTER_WEB_CANVASKIT_URL',
  defaultValue: 'https://unpkg.com/canvaskit-wasm@0.19.0/bin/',
);

/// Initialize CanvasKit.
///
/// This calls `CanvasKitInit` and assigns the global [canvasKit] object.
Future<void> initializeCanvasKit() {
  final Completer<void> canvasKitCompleter = Completer<void>();
  late StreamSubscription<html.Event> loadSubscription;
  loadSubscription = domRenderer.canvasKitScript!.onLoad.listen((_) {
    loadSubscription.cancel();
    final CanvasKitInitPromise canvasKitInitPromise = CanvasKitInit(CanvasKitInitOptions(
      locateFile: js.allowInterop((String file, String unusedBase) => canvasKitBaseUrl + file),
    ));
    canvasKitInitPromise.then(js.allowInterop((CanvasKit ck) {
      canvasKit = ck;
      windowFlutterCanvasKit = canvasKit;
      canvasKitCompleter.complete();
    }));
  });

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
