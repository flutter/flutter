// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

// TODO(mdebbar): add other strategies.

// Some parts of this file were inspired/copied from the AngularDart router.

/// Ensures that [str] is prefixed with [leading]. If [str] is already prefixed,
/// it'll be returned unchanged. If it's not, this function will prefix it.
///
/// The [applyWhenEmpty] flag controls whether this function should prefix [str]
/// or not when it's an empty string.
///
/// ```dart
/// ensureLeading('/path', '/'); // "/path"
/// ensureLeading('path', '/'); // "/path"
/// ensureLeading('', '/'); // "/"
/// ensureLeading('', '/', applyWhenEmpty: false); // ""
/// ```
String ensureLeading(String str, String leading, {bool applyWhenEmpty = true}) {
  if (str.isEmpty && !applyWhenEmpty) {
    return str;
  }
  return str.startsWith(leading) ? str : '$leading$str';
}

/// `LocationStrategy` is responsible for representing and reading route state
/// from the browser's URL. At the moment, only one strategy is implemented:
/// [HashLocationStrategy].
///
/// This is used by [BrowserHistory] to interact with browser history APIs.
abstract class LocationStrategy {
  const LocationStrategy();

  /// Subscribes to popstate events and returns a function that could be used to
  /// unsubscribe from popstate events.
  ui.VoidCallback onPopState(html.EventListener fn);

  /// The active path in the browser history.
  String get path;

  /// Given a path that's internal to the app, create the external url that
  /// will be used in the browser.
  String prepareExternalUrl(String internalUrl);

  /// Push a new history entry.
  void pushState(dynamic state, String title, String url);

  /// Replace the currently active history entry.
  void replaceState(dynamic state, String title, String url);

  /// Go to the previous history entry.
  Future<void> back();
}

/// This is an implementation of [LocationStrategy] that uses the browser URL's
/// [hash fragments](https://en.wikipedia.org/wiki/Uniform_Resource_Locator#Syntax)
/// to represent its state.
///
/// In order to use this [LocationStrategy] for an app, it needs to be set in
/// [ui.window.webOnlyLocationStrategy]:
///
/// ```dart
/// import 'package:flutter_web/material.dart';
/// import 'package:flutter_web/ui.dart' as ui;
///
/// void main() {
///   ui.window.webOnlyLocationStrategy = const ui.HashLocationStrategy();
///   runApp(MyApp());
/// }
/// ```
class HashLocationStrategy extends LocationStrategy {
  final PlatformLocation _platformLocation;

  const HashLocationStrategy(
      [this._platformLocation = const BrowserPlatformLocation()]);

  @override
  ui.VoidCallback onPopState(html.EventListener fn) {
    _platformLocation.onPopState(fn);
    return () => _platformLocation.offPopState(fn);
  }

  @override
  String get path {
    // the hash value is always prefixed with a `#`
    // and if it is empty then it will stay empty
    String path = _platformLocation.hash ?? '';
    // Dart will complain if a call to substring is
    // executed with a position value that exceeds the
    // length of string.
    path = path.isEmpty ? path : path.substring(1);
    // The path, by convention, should always contain a leading '/'.
    return ensureLeading(path, '/');
  }

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
  Future<void> back() {
    _platformLocation.back();
    return _waitForPopState();
  }

  /// Waits until the next popstate event is fired. This is useful for example
  /// to wait until the browser has handled the `history.back` transition.
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

/// `PlatformLocation` encapsulates all calls to DOM apis, which allows the
/// [LocationStrategy] classes to be platform agnostic and testable.
///
/// The `PlatformLocation` class is used directly by all implementations of
/// [LocationStrategy] when they need to interact with the DOM apis like
/// pushState, popState, etc...
abstract class PlatformLocation {
  const PlatformLocation();

  void onPopState(html.EventListener fn);
  void offPopState(html.EventListener fn);

  void onHashChange(html.EventListener fn);
  void offHashChange(html.EventListener fn);

  String get pathname;
  String get search;
  String get hash;

  void pushState(dynamic state, String title, String url);
  void replaceState(dynamic state, String title, String url);
  void back();
}

/// An implementation of [PlatformLocation] for the browser.
class BrowserPlatformLocation extends PlatformLocation {
  html.Location get _location => html.window.location;
  html.History get _history => html.window.history;

  const BrowserPlatformLocation();

  @override
  void onPopState(html.EventListener fn) {
    html.window.addEventListener('popstate', fn);
  }

  @override
  void offPopState(html.EventListener fn) {
    html.window.removeEventListener('popstate', fn);
  }

  @override
  void onHashChange(html.EventListener fn) {
    html.window.addEventListener('hashchange', fn);
  }

  @override
  void offHashChange(html.EventListener fn) {
    html.window.removeEventListener('hashchange', fn);
  }

  @override
  String get pathname => _location.pathname;

  @override
  String get search => _location.search;

  @override
  String get hash => _location.hash;

  @override
  void pushState(dynamic state, String title, String url) {
    _history.pushState(state, title, url);
  }

  @override
  void replaceState(dynamic state, String title, String url) {
    _history.replaceState(state, title, url);
  }

  @override
  void back() {
    _history.back();
  }
}
