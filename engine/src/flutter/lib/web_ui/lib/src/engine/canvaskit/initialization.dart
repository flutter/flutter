// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library canvaskit_initialization;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:js/js.dart';

import '../../engine.dart' show kProfileMode;
import '../browser_detection.dart';
import '../configuration.dart';
import '../dom_renderer.dart';
import 'canvaskit_api.dart';
import 'fonts.dart';

/// A JavaScript entrypoint that allows developer to set rendering backend
/// at runtime before launching the application.
@JS('window.flutterWebRenderer')
external String? get requestedRendererType;

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

    // TODO(hterkelsen): Rather than this monkey-patch hack, we should
    // build CanvasKit ourselves. See:
    // https://github.com/flutter/flutter/issues/52588

    // Monkey-patch the top-level `module`  and `exports` objects so that
    // CanvasKit doesn't attempt to register itself as an anonymous module.
    //
    // The idea behind making these fake `exports` and `module` objects is
    // that `canvaskit.js` contains the following lines of code:
    //
    //     if (typeof exports === 'object' && typeof module === 'object')
    //       module.exports = CanvasKitInit;
    //     else if (typeof define === 'function' && define['amd'])
    //       define([], function() { return CanvasKitInit; });
    //
    // We need to avoid hitting the case where CanvasKit defines an anonymous
    // module, since this breaks RequireJS, which DDC and some plugins use.
    // Temporarily removing the `define` function won't work because RequireJS
    // could load in between this code running and the CanvasKit code running.
    // Also, we cannot monkey-patch the `define` function because it is
    // non-configurable (it is a top-level 'var').

    // First check if `exports` and `module` are already defined. If so, then
    // CommonJS is being used, and we shouldn't have any problems.
    final js.JsFunction objectConstructor = js.context['Object'] as js.JsFunction;
    if (js.context['exports'] == null) {
      final js.JsObject exportsAccessor = js.JsObject.jsify(<String, dynamic>{
        'get': js.allowInterop(() {
          if (html.document.currentScript == _canvasKitScript) {
            return js.JsObject(objectConstructor);
          } else {
            return js.context['_flutterWebCachedExports'];
          }
        }),
        'set': js.allowInterop((dynamic value) {
          js.context['_flutterWebCachedExports'] = value;
        }),
        'configurable': true,
      });
      objectConstructor.callMethod(
          'defineProperty', <dynamic>[js.context, 'exports', exportsAccessor]);
    }
    if (js.context['module'] == null) {
      final js.JsObject moduleAccessor = js.JsObject.jsify(<String, dynamic>{
        'get': js.allowInterop(() {
          if (html.document.currentScript == _canvasKitScript) {
            return js.JsObject(objectConstructor);
          } else {
            return js.context['_flutterWebCachedModule'];
          }
        }),
        'set': js.allowInterop((dynamic value) {
          js.context['_flutterWebCachedModule'] = value;
        }),
        'configurable': true,
      });
      objectConstructor.callMethod(
          'defineProperty', <dynamic>[js.context, 'module', moduleAccessor]);
    }
    html.document.head!.append(_canvasKitScript!);
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
