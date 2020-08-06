// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// EXPERIMENTAL: Enable the Skia-based rendering backend.
const bool experimentalUseSkia =
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
  defaultValue: 'https://unpkg.com/canvaskit-wasm@0.17.3/bin/',
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
