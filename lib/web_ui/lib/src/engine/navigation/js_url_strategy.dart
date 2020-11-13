// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

typedef _PathGetter = String Function();

typedef _StateGetter = Object? Function();

typedef _AddPopStateListener = ui.VoidCallback Function(html.EventListener);

typedef _StringToString = String Function(String);

typedef _StateOperation = void Function(
    Object? state, String title, String url);

typedef _HistoryMove = Future<void> Function(int count);

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
    required _PathGetter getPath,
    required _StateGetter getState,
    required _AddPopStateListener addPopStateListener,
    required _StringToString prepareExternalUrl,
    required _StateOperation pushState,
    required _StateOperation replaceState,
    required _HistoryMove go,
  });

  /// Adds a listener to the `popstate` event and returns a function that, when
  /// invoked, removes the listener.
  external ui.VoidCallback addPopStateListener(html.EventListener fn);

  /// Returns the active path in the browser.
  external String getPath();

  /// Returns the history state in the browser.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/state
  external Object? getState();

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
