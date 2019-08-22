// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// EXPERIMENTAL: Enable the Skia-based rendering backend.
const bool experimentalUseSkia =
    bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);

/// The URL to use when downloading the CanvasKit script and associated wasm.
const String canvasKitBaseUrl = 'https://unpkg.com/canvaskit-wasm@0.6.0/bin/';

/// Initialize the Skia backend.
///
/// This calls `CanvasKitInit` and assigns the global [canvasKit] object.
Future<void> initializeSkia() {
  final Completer<void> canvasKitCompleter = Completer<void>();
  StreamSubscription<html.Event> loadSubscription;
  loadSubscription = domRenderer.canvasKitScript.onLoad.listen((_) {
    loadSubscription.cancel();
    final js.JsObject canvasKitInitArgs = js.JsObject.jsify(<String, dynamic>{
      'locateFile': (String file, String unusedBase) => canvasKitBaseUrl + file,
    });
    final js.JsObject canvasKitInit =
        js.JsObject(js.context['CanvasKitInit'], <dynamic>[canvasKitInitArgs]);
    final js.JsObject canvasKitInitPromise = canvasKitInit.callMethod('ready');
    canvasKitInitPromise.callMethod('then', <dynamic>[
      (js.JsObject ck) {
        canvasKit = ck;
        canvasKitCompleter.complete();
      },
    ]);
  });
  return canvasKitCompleter.future;
}

/// The entrypoint into all CanvasKit functions and classes.
///
/// This is created by [initializeSkia].
js.JsObject canvasKit;

/// The Skia font collection.
SkiaFontCollection skiaFontCollection;
