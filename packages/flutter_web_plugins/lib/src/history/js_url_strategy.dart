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

typedef _UrlStrategyListener = void Function(JsUrlStrategy);

// KEEP THIS IN SYNC WITH THE JS NAME IN THE WEB ENGINE!
// Find it at: `lib/src/engine/window.dart`.
@JS('_flutter_web_set_location_strategy')
/// A JavaScript hook to customize the URL strategy of a Flutter app.
external _UrlStrategyListener get onUrlStrategy;

typedef _PathGetter = String Function();

typedef _StateGetter = dynamic Function();

typedef _OnPopState = ui.VoidCallback Function(html.EventListener);

typedef _StringToString = String Function(String);

typedef _StateOperation = void Function(
    dynamic state, String title, String url);

typedef _HistoryMove = Future<void> Function(int count);

/// Given a Dart implementation of URL strategy, it converts it to a JavaScript
/// URL strategy that be passed through JS interop.
JsUrlStrategy convertToJsUrlStrategy(UrlStrategy strategy) {
  if (strategy == null) {
    return null;
  }

  return JsUrlStrategy(
    getPath: allowInterop(strategy.getPath),
    getState: allowInterop(strategy.getState),
    onPopState: allowInterop(strategy.onPopState),
    prepareExternalUrl: allowInterop(strategy.prepareExternalUrl),
    pushState: allowInterop(strategy.pushState),
    replaceState: allowInterop(strategy.replaceState),
    go: allowInterop(strategy.go),
    // getBaseHref: allowInterop(strategy.getBaseHref),
  );
}

/// The JavaScript representation of a URL strategy.
///
/// This is used to pass URL strategy implementations across a JS-interop
/// bridge.
@JS()
@anonymous
abstract class JsUrlStrategy {
  /// Creates an instance of [JsUrlStrategy] from a bag of URL strategy
  /// functions.
  external factory JsUrlStrategy({
    @required _PathGetter getPath,
    @required _StateGetter getState,
    @required _OnPopState onPopState,
    @required _StringToString prepareExternalUrl,
    @required _StateOperation pushState,
    @required _StateOperation replaceState,
    @required _HistoryMove go,
  });

  /// Subscribes to popstate events and returns a function that could be used to
  /// unsubscribe from popstate events.
  external ui.VoidCallback onPopState(html.EventListener fn);

  /// Returns the active path in the browser.
  external String getPath();

  /// Returns the history state in the browser.
  external dynamic getState();

  /// Given a path that's internal to the app, create the external url that
  /// will be used in the browser.
  external String prepareExternalUrl(String internalUrl);

  /// Push a new history entry.
  external void pushState(dynamic state, String title, String url);

  /// Replace the currently active history entry.
  external void replaceState(dynamic state, String title, String url);

  /// Moves forwards or backwards through the history stack.
  external Future<void> go(int count);
}
