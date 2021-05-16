// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library js_location_strategy;

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:js/js.dart';
import 'package:meta/meta.dart';

import 'url_strategy.dart';

typedef _JsSetUrlStrategy = void Function(JsUrlStrategy?);

/// A JavaScript hook to customize the URL strategy of a Flutter app.
//
// Keep this in sync with the JS name in the web engine. Find it at:
// https://github.com/flutter/engine/blob/custom_location_strategy/lib/web_ui/lib/src/engine/navigation/js_url_strategy.dart
//
// TODO(mdebbar): Add integration test https://github.com/flutter/flutter/issues/66852
@JS('_flutter_web_set_location_strategy')
external _JsSetUrlStrategy get jsSetUrlStrategy;

typedef _PathGetter = String Function();

typedef _StateGetter = Object? Function();

typedef _AddPopStateListener = ui.VoidCallback Function(html.EventListener);

typedef _StringToString = String Function(String);

typedef _StateOperation = void Function(
    Object state, String title, String url);

typedef _HistoryMove = Future<void> Function(int count);

/// Given a Dart implementation of URL strategy, converts it to a JavaScript
/// URL strategy to be passed through JS interop.
JsUrlStrategy convertToJsUrlStrategy(UrlStrategy strategy) {
  return JsUrlStrategy(
    getPath: allowInterop(strategy.getPath),
    getState: allowInterop(strategy.getState),
    addPopStateListener: allowInterop(strategy.addPopStateListener),
    prepareExternalUrl: allowInterop(strategy.prepareExternalUrl),
    pushState: allowInterop(strategy.pushState),
    replaceState: allowInterop(strategy.replaceState),
    go: allowInterop(strategy.go),
  );
}

/// The JavaScript representation of a URL strategy.
///
/// This is used to pass URL strategy implementations across a JS-interop
/// bridge from the app to the engine.
@JS()
@anonymous
abstract class JsUrlStrategy {
  /// Creates an instance of [JsUrlStrategy] from a bag of URL strategy
  /// functions.
  external factory JsUrlStrategy({
    @required _PathGetter getPath,
    @required _StateGetter getState,
    @required _AddPopStateListener addPopStateListener,
    @required _StringToString prepareExternalUrl,
    @required _StateOperation pushState,
    @required _StateOperation replaceState,
    @required _HistoryMove go,
  });

  /// Adds a listener to the `popstate` event and returns a function that
  /// removes the listener.
  external ui.VoidCallback addPopStateListener(html.EventListener fn);

  /// Returns the active path in the browser.
  external String getPath();

  /// Returns the history state in the browser.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/state
  external Object getState();

  /// Given a path that's internal to the app, create the external url that
  /// will be used in the browser.
  external String prepareExternalUrl(String internalUrl);

  /// Push a new history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/pushState
  external void pushState(Object? state, String title, String url);

  /// Replace the currently active history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
  external void replaceState(Object? state, String title, String url);

  /// Moves forwards or backwards through the history stack.
  ///
  /// A negative [count] value causes a backward move in the history stack. And
  /// a positive [count] value causs a forward move.
  ///
  /// Examples:
  ///
  /// * `go(-2)` moves back 2 steps in history.
  /// * `go(3)` moves forward 3 steps in hisotry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/go
  external Future<void> go(int count);
}
