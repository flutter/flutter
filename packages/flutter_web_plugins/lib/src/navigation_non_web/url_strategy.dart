// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

/// Signature of an html event listener.
typedef EventListener = void Function(Object event);

/// Change the strategy to use for handling browser URL.
///
/// Setting this to null disables all integration with the browser history.
void setUrlStrategy(UrlStrategy? strategy) {
  // No-op in non-web platforms.
}

/// Use the [PathUrlStrategy] to handle the browser URL.
void usePathUrlStrategy() {
  // No-op in non-web platforms.
}

/// Represents and reads route state from the browser's URL.
///
/// By default, the [HashUrlStrategy] subclass is used if the app doesn't
/// specify one.
abstract class UrlStrategy {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const UrlStrategy();

  /// Adds a listener to the `popstate` event and returns a function that, when
  /// invoked, removes the listener.
  ui.VoidCallback addPopStateListener(EventListener fn);

  /// Returns the active path in the browser.
  String getPath();

  /// The state of the current browser history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/state
  Object? getState();

  /// Given a path that's internal to the app, create the external url that
  /// will be used in the browser.
  String prepareExternalUrl(String internalUrl);

  /// Push a new history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/pushState
  void pushState(Object state, String title, String url);

  /// Replace the currently active history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
  void replaceState(Object state, String title, String url);

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
  Future<void> go(int count);
}

/// Uses the browser URL's [hash fragments](https://en.wikipedia.org/wiki/Uniform_Resource_Locator#Syntax)
/// to represent its state.
///
/// By default, this class is used as the URL strategy for the app. However,
/// this class is still useful for apps that want to extend it.
///
/// In order to use [HashUrlStrategy] for an app, it needs to be set like this:
///
/// ```dart
/// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
///
/// // Somewhere before calling `runApp()` do:
/// setUrlStrategy(const HashUrlStrategy());
/// ```
class HashUrlStrategy extends UrlStrategy {
  /// Creates an instance of [HashUrlStrategy].
  ///
  /// The [PlatformLocation] parameter is useful for testing to mock out browser
  /// interations.
  const HashUrlStrategy([PlatformLocation? _platformLocation]);

  @override
  ui.VoidCallback addPopStateListener(EventListener fn) {
    // No-op.
    return () {};
  }

  @override
  String getPath() => '';

  @override
  Object? getState() => null;

  @override
  String prepareExternalUrl(String internalUrl) => '';

  @override
  void pushState(Object state, String title, String url) {
    // No-op.
  }

  @override
  void replaceState(Object state, String title, String url) {
    // No-op.
  }

  @override
  Future<void> go(int count) async {
    // No-op.
  }
}

/// Uses the browser URL's pathname to represent Flutter's route name.
///
/// In order to use [PathUrlStrategy] for an app, it needs to be set like this:
///
/// ```dart
/// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
///
/// // Somewhere before calling `runApp()` do:
/// setUrlStrategy(PathUrlStrategy());
/// ```
class PathUrlStrategy extends HashUrlStrategy {
  /// Creates an instance of [PathUrlStrategy].
  ///
  /// The [PlatformLocation] parameter is useful for testing to mock out browser
  /// interations.
  PathUrlStrategy([PlatformLocation? _platformLocation])
      : super(_platformLocation);

  @override
  String getPath() => '';

  @override
  String prepareExternalUrl(String internalUrl) => '';
}

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
  void pushState(Object state, String title, String url);

  /// Replaces the current entry in the browser history stack.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
  void replaceState(Object state, String title, String url);

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
  void go(int count);

  /// The base href where the Flutter app is being served.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base
  String? getBaseHref();
}
