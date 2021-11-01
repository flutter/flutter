// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import '../navigation_common/url_strategy.dart';
import 'js_url_strategy.dart';
import 'utils.dart';

/// Saves the current [UrlStrategy] to be accessed by [urlStrategy] or
/// [setUrlStrategy].
///
/// This is particularly required for web plugins relying on valid URL
/// encoding.
//
// Keep this in sync with the default url strategy in the web engine.
// Find it at:
// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/window.dart#L360
//
UrlStrategy? _urlStrategy = const HashUrlStrategy();

/// Returns the present [UrlStrategy] for handling the browser URL.
///
/// In case null is returned, the browser integration has been manually
/// disabled by [setUrlStrategy].
UrlStrategy? get urlStrategy => _urlStrategy;

/// Change the strategy to use for handling browser URL.
///
/// Setting this to null disables all integration with the browser history.
void setUrlStrategy(UrlStrategy? strategy) {
  _urlStrategy = strategy;

  JsUrlStrategy? jsUrlStrategy;
  if (strategy != null) {
    jsUrlStrategy = convertToJsUrlStrategy(strategy);
  }
  jsSetUrlStrategy(jsUrlStrategy);
}

/// Use the [PathUrlStrategy] to handle the browser URL.
void usePathUrlStrategy() {
  setUrlStrategy(PathUrlStrategy());
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
  /// interactions.
  const HashUrlStrategy(
      [this._platformLocation = const BrowserPlatformLocation()]);

  final PlatformLocation _platformLocation;

  @override
  ui.VoidCallback addPopStateListener(EventListener fn) {
    _platformLocation.addPopStateListener(fn);
    return () => _platformLocation.removePopStateListener(fn);
  }

  @override
  String getPath() {
    // the hash value is always prefixed with a `#`
    // and if it is empty then it will stay empty
    final String path = _platformLocation.hash;
    assert(path.isEmpty || path.startsWith('#'));

    // We don't want to return an empty string as a path. Instead we default to "/".
    if (path.isEmpty || path == '#') {
      return '/';
    }
    // At this point, we know [path] starts with "#" and isn't empty.
    return path.substring(1);
  }

  @override
  Object? getState() => _platformLocation.state;

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
  void pushState(Object? state, String title, String url) {
    _platformLocation.pushState(state, title, prepareExternalUrl(url));
  }

  @override
  void replaceState(Object? state, String title, String url) {
    _platformLocation.replaceState(state, title, prepareExternalUrl(url));
  }

  @override
  Future<void> go(int count) {
    _platformLocation.go(count);
    return _waitForPopState();
  }

  /// Waits until the next popstate event is fired.
  ///
  /// This is useful, for example, to wait until the browser has handled the
  /// `history.back` transition.
  Future<void> _waitForPopState() {
    final Completer<void> completer = Completer<void>();
    late ui.VoidCallback unsubscribe;
    unsubscribe = addPopStateListener((_) {
      unsubscribe();
      completer.complete();
    });
    return completer.future;
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
  /// interactions.
  PathUrlStrategy([
    PlatformLocation _platformLocation = const BrowserPlatformLocation(),
  ])  : _basePath = stripTrailingSlash(extractPathname(checkBaseHref(
          _platformLocation.getBaseHref(),
        ))),
        super(_platformLocation);

  final String _basePath;

  @override
  String getPath() {
    final String path = _platformLocation.pathname + _platformLocation.search;
    if (_basePath.isNotEmpty && path.startsWith(_basePath)) {
      return ensureLeadingSlash(path.substring(_basePath.length));
    }
    return ensureLeadingSlash(path);
  }

  @override
  String prepareExternalUrl(String internalUrl) {
    if (internalUrl.isNotEmpty && !internalUrl.startsWith('/')) {
      internalUrl = '/$internalUrl';
    }
    return '$_basePath$internalUrl';
  }
}

/// Delegates to real browser APIs to provide platform location functionality.
class BrowserPlatformLocation extends PlatformLocation {
  /// Default constructor for [BrowserPlatformLocation].
  const BrowserPlatformLocation();

  // Default value for [pathname] when it's not set in window.location.
  // According to MDN this should be ''. Chrome seems to return '/'.
  static const String _defaultPathname = '';

  // Default value for [search] when it's not set in window.location.
  // According to both chrome, and the MDN, this is ''.
  static const String _defaultSearch = '';

  html.Location get _location => html.window.location;

  html.History get _history => html.window.history;

  @override
  void addPopStateListener(html.EventListener fn) {
    html.window.addEventListener('popstate', fn);
  }

  @override
  void removePopStateListener(html.EventListener fn) {
    html.window.removeEventListener('popstate', fn);
  }

  @override
  String get pathname => _location.pathname ?? _defaultPathname;

  @override
  String get search => _location.search ?? _defaultSearch;

  @override
  String get hash => _location.hash;

  @override
  Object? get state => _history.state;

  @override
  void pushState(Object? state, String title, String url) {
    _history.pushState(state, title, url);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    _history.replaceState(state, title, url);
  }

  @override
  void go(int count) {
    _history.go(count);
  }

  @override
  String? getBaseHref() => getBaseElementHrefFromDom();
}
