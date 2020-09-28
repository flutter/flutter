// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'js_url_strategy.dart';
import 'utils.dart';

/// Change the strategy to use for handling browser URL.
///
/// Setting this to null, all integration with browser history and URL will
/// be disabled.
void setUrlStrategy(UrlStrategy strategy) {
  onUrlStrategy(convertToJsUrlStrategy(strategy));
}

/// [UrlStrategy] is responsible for representing and reading route state
/// from the browser's URL.
///
/// At the moment, only one strategy is implemented: [HashUrlStrategy].
///
/// This is used by [BrowserHistory] to interact with browser history APIs.
abstract class UrlStrategy {
  /// This constructor is here only to allow subclasses to be const.
  const UrlStrategy();

  /// Subscribes to popstate events and returns a function that could be used to
  /// unsubscribe from popstate events.
  ui.VoidCallback onPopState(html.EventListener fn);

  /// Returns the active path in the browser.
  String getPath();

  /// The state of the current browser history entry.
  dynamic getState();

  /// Given a path that's internal to the app, create the external url that
  /// will be used in the browser.
  String prepareExternalUrl(String internalUrl);

  /// Push a new history entry.
  void pushState(dynamic state, String title, String url);

  /// Replace the currently active history entry.
  void replaceState(dynamic state, String title, String url);

  /// Moves forwards or backwards through the history stack.
  Future<void> go(int count);
}

/// This is an implementation of [UrlStrategy] that uses the browser URL's
/// [hash fragments](https://en.wikipedia.org/wiki/Uniform_Resource_Locator#Syntax)
/// to represent its state.
///
/// In order to use this [UrlStrategy] for an app, it needs to be set like this:
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
  /// The [PlatformLocation] parameter is useful for testing to avoid
  /// interacting with the actual browser.
  const HashUrlStrategy(
      [this._platformLocation = const BrowserPlatformLocation()]);

  final PlatformLocation _platformLocation;

  @override
  ui.VoidCallback onPopState(html.EventListener fn) {
    _platformLocation.onPopState(fn);
    return () => _platformLocation.offPopState(fn);
  }

  @override
  String getPath() {
    // the hash value is always prefixed with a `#`
    // and if it is empty then it will stay empty
    final String path = _platformLocation.hash ?? '';
    assert(path.isEmpty || path.startsWith('#'));

    // We don't want to return an empty string as a path. Instead we default to "/".
    if (path.isEmpty || path == '#') {
      return '/';
    }
    // At this point, we know [path] starts with "#" and isn't empty.
    return path.substring(1);
  }

  @override
  dynamic getState() => _platformLocation.state;

  @override
  String prepareExternalUrl(String internalUrl) {
    // It's convention that if the hash path is empty, we omit the `#`; however,
    // if the empty URL is pushed it won't replace any existing fragment. So
    // when the hash path is empty, we instead return the location's path and
    // query.
    return internalUrl.isEmpty
        ? '${_platformLocation.pathname}${_platformLocation.search}'
        : '#$internalUrl';
  }

  @override
  void pushState(dynamic state, String title, String url) {
    _platformLocation.pushState(state, title, prepareExternalUrl(url));
  }

  @override
  void replaceState(dynamic state, String title, String url) {
    _platformLocation.replaceState(state, title, prepareExternalUrl(url));
  }

  @override
  Future<void> go(int count) {
    _platformLocation.go(count);
    return _waitForPopState();
  }

  /// Waits until the next popstate event is fired.
  ///
  /// This is useful for example to wait until the browser has handled the
  /// `history.back` transition.
  Future<void> _waitForPopState() {
    final Completer<void> completer = Completer<void>();
    ui.VoidCallback unsubscribe;
    unsubscribe = onPopState((_) {
      unsubscribe();
      completer.complete();
    });
    return completer.future;
  }
}

/// This is an implementation of [UrlStrategy] that uses the browser URL's
/// pathname to represent Flutter's route name.
///
/// In order to use this [UrlStrategy] for an app, it needs to be set like this:
///
/// ```dart
/// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
///
/// // Somewhere before calling `runApp()` do:
/// setUrlStrategy(PathUrlStrategy());
/// ```
class PathUrlStrategy extends UrlStrategy {
  /// Creates an instance of [PathUrlStrategy].
  ///
  /// The [PlatformLocation] parameter is useful for testing to avoid
  /// interacting with the actual browser.
  PathUrlStrategy([
    this._platformLocation = const BrowserPlatformLocation(),
  ]) : _basePath = stripTrailingSlash(extractPathname(checkBaseHref(
          _platformLocation.getBaseHref(),
        )));

  final PlatformLocation _platformLocation;
  final String _basePath;

  @override
  ui.VoidCallback onPopState(html.EventListener fn) {
    _platformLocation.onPopState(fn);
    return () => _platformLocation.offPopState(fn);
  }

  @override
  String getPath() {
    final String path = _platformLocation.pathname + _platformLocation.search;
    if (_basePath.isNotEmpty && path.startsWith(_basePath)) {
      return ensureLeadingSlash(path.substring(_basePath.length));
    }
    return ensureLeadingSlash(path);
  }

  @override
  dynamic getState() => _platformLocation.state;

  @override
  String prepareExternalUrl(String internalUrl) {
    if (internalUrl.isNotEmpty && !internalUrl.startsWith('/')) {
      internalUrl = '/$internalUrl';
    }
    return '$_basePath$internalUrl';
  }

  @override
  void pushState(dynamic state, String title, String url) {
    _platformLocation.pushState(state, title, prepareExternalUrl(url));
  }

  @override
  void replaceState(dynamic state, String title, String url) {
    _platformLocation.replaceState(state, title, prepareExternalUrl(url));
  }

  @override
  Future<void> go(int count) {
    _platformLocation.go(count);
    return _waitForPopState();
  }

  /// Waits until the next popstate event is fired.
  ///
  /// This is useful for example to wait until the browser has handled the
  /// `history.back` transition.
  Future<void> _waitForPopState() {
    final Completer<void> completer = Completer<void>();
    ui.VoidCallback unsubscribe;
    unsubscribe = onPopState((_) {
      unsubscribe();
      completer.complete();
    });
    return completer.future;
  }
}

/// [PlatformLocation] encapsulates all calls to DOM apis, which allows the
/// [UrlStrategy] classes to be platform agnostic and testable.
///
/// The [PlatformLocation] class is used directly by all implementations of
/// [UrlStrategy] when they need to interact with the DOM apis like
/// pushState, popState, etc...
abstract class PlatformLocation {
  /// This constructor is here only to allow subclasses to be const.
  const PlatformLocation();

  /// Registers an event listener for the `onpopstate` event.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
  void onPopState(html.EventListener fn);

  /// Unregisters the given listener from the`popstate` event.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate
  void offPopState(html.EventListener fn);

  /// The [pathname](https://developer.mozilla.org/en-US/docs/Web/API/Location/pathname)
  /// part of the URL in the browser address bar.
  String get pathname;

  /// The `query` part of the URL in the browser address bar.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Location/search
  String get search;

  /// The `hash]` part of the URL in the browser address bar.
  ///
  /// See: ttps://developer.mozilla.org/en-US/docs/Web/API/Location/hash
  String get hash;

  /// The `state` in the current history entry.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/state
  dynamic get state;

  /// Adds a new entry to the browser history stack.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/pushState
  void pushState(dynamic state, String title, String url);

  /// Replaces the current entry in the browser history stack.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
  void replaceState(dynamic state, String title, String url);

  /// Moves forwards or backwards through the history stack.
  ///
  /// A negative [count] moves backwards, while a positive [count] moves
  /// forwards.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/History/go
  void go(int count);

  /// The base href where the flutter app is being served.
  String getBaseHref();
}

/// An implementation of [PlatformLocation] for the browser.
class BrowserPlatformLocation extends PlatformLocation {
  /// Default constructor for [BrowserPlatformLocation].
  const BrowserPlatformLocation();

  html.Location get _location => html.window.location;
  html.History get _history => html.window.history;

  @override
  void onPopState(html.EventListener fn) {
    html.window.addEventListener('popstate', fn);
  }

  @override
  void offPopState(html.EventListener fn) {
    html.window.removeEventListener('popstate', fn);
  }

  @override
  String get pathname => _location.pathname;

  @override
  String get search => _location.search;

  @override
  String get hash => _location.hash;

  @override
  dynamic get state => _history.state;

  @override
  void pushState(dynamic state, String title, String url) {
    _history.pushState(state, title, url);
  }

  @override
  void replaceState(dynamic state, String title, String url) {
    _history.replaceState(state, title, url);
  }

  @override
  void go(int count) {
    _history.go(count);
  }

  @override
  String getBaseHref() => html.document.baseUri;
}
