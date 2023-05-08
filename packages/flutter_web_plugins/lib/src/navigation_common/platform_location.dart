// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Function type that handles pop state events.
typedef EventListener = dynamic Function(Object event);

/// Encapsulates all calls to DOM apis, which allows the [UrlStrategy] classes
/// to be platform agnostic and testable.
///
/// For convenience, the [PlatformLocation] class can be used by implementations
/// of [UrlStrategy] to interact with DOM apis like pushState, popState, etc.
abstract class PlatformLocation {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PlatformLocation();

  /// Registers an event listener for the `popstate` event.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
  void addPopStateListener(EventListener fn);

  /// Unregisters the given listener (added by [addPopStateListener]) from the
  /// `popstate` event.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
  void removePopStateListener(EventListener fn);

  /// The `pathname` part of the URL in the browser address bar.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Location/pathname
  String get pathname;

  /// The `query` part of the URL in the browser address bar.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Location/search
  String get search;

  /// The `hash` part of the URL in the browser address bar.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Location/hash
  String get hash;

  /// The `state` in the current history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/state
  Object? get state;

  /// Adds a new entry to the browser history stack.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/pushState
  void pushState(Object? state, String title, String url);

  /// Replaces the current entry in the browser history stack.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
  void replaceState(Object? state, String title, String url);

  /// Moves forwards or backwards through the history stack.
  ///
  /// A negative [count] value causes a backward move in the history stack. And
  /// a positive [count] value causes a forward move.
  ///
  /// Examples:
  ///
  /// * `go(-2)` moves back 2 steps in history.
  /// * `go(3)` moves forward 3 steps in history.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/go
  void go(int count);

  /// The base href where the Flutter app is being served.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
  String? getBaseHref();
}
