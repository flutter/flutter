// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
library canvaskit_initialization;

import 'dart:async';
import 'dart:html' as html;

import '../../engine.dart' show kProfileMode;
import '../browser_detection.dart';
import '../configuration.dart';
import '../embedder.dart';
import '../safe_browser_api.dart';
import 'canvaskit_api.dart';
import 'fonts.dart';

/// Whether to use CanvasKit as the rendering backend.
bool get useCanvasKit => FlutterConfiguration.flutterWebAutoDetect ? _detectRenderer() : FlutterConfiguration.useSkia;

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

String get canvasKitBuildUrl =>
    configuration.canvasKitBaseUrl + (kProfileMode ? 'profiling/' : '');
String get canvasKitJavaScriptBindingsUrl =>
    canvasKitBuildUrl + 'canvaskit.js';
String canvasKitWasmModuleUrl(String file) => _currentCanvasKitBase! + file;

/// The script element which CanvasKit is loaded from.
html.ScriptElement? _canvasKitScript;

/// A [Future] which completes when the CanvasKit script has been loaded.
Future<void>? _canvasKitLoaded;

/// The currently used base URL for loading CanvasKit.
String? _currentCanvasKitBase;

/// Initialize CanvasKit.
///
/// This calls `CanvasKitInit` and assigns the global [canvasKit] object.
Future<void> initializeCanvasKit({String? canvasKitBase}) {
  final Completer<void> canvasKitCompleter = Completer<void>();
  if (windowFlutterCanvasKit != null) {
    canvasKit = windowFlutterCanvasKit!;
    canvasKitCompleter.complete();
  } else {
    _startDownloadingCanvasKit(canvasKitBase);
    _canvasKitLoaded!.then((_) {
      final CanvasKitInitPromise canvasKitInitPromise =
          CanvasKitInit(CanvasKitInitOptions(
        locateFile: allowInterop(
            (String file, String unusedBase) => canvasKitWasmModuleUrl(file)),
      ));
      canvasKitInitPromise.then(allowInterop((CanvasKit ck) {
        canvasKit = ck;
        windowFlutterCanvasKit = canvasKit;
        canvasKitCompleter.complete();
      }));
    });
  }

  /// Add a Skia scene host.
  skiaSceneHost = html.Element.tag('flt-scene');
  flutterViewEmbedder.renderScene(skiaSceneHost);
  return canvasKitCompleter.future;
}

/// Starts downloading the CanvasKit JavaScript file at [canvasKitBase] and sets
/// [_canvasKitLoaded].
void _startDownloadingCanvasKit(String? canvasKitBase) {
  final String canvasKitJavaScriptUrl = canvasKitBase != null
      ? canvasKitBase + 'canvaskit.js'
      : canvasKitJavaScriptBindingsUrl;
  _currentCanvasKitBase = canvasKitBase ?? canvasKitBuildUrl;
  // Only reset CanvasKit if it's not already available.
  if (windowFlutterCanvasKit == null) {
    _canvasKitScript?.remove();
    _canvasKitScript = html.ScriptElement();
    _canvasKitScript!.src = canvasKitJavaScriptUrl;

    final Completer<void> canvasKitLoadCompleter = Completer<void>();
    _canvasKitLoaded = canvasKitLoadCompleter.future;

    late StreamSubscription<html.Event> loadSubscription;
    loadSubscription = _canvasKitScript!.onLoad.listen((_) {
      loadSubscription.cancel();
      canvasKitLoadCompleter.complete();
    });

    patchCanvasKitModule(_canvasKitScript!);
  }
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
