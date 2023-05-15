// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import '../navigation_common/platform_location.dart';
import 'utils.dart';

export 'dart:ui_web' show UrlStrategy;

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
ui_web.UrlStrategy? _urlStrategy = const HashUrlStrategy();

/// Returns the present [UrlStrategy] for handling the browser URL.
///
/// In case null is returned, the browser integration has been manually
/// disabled by [setUrlStrategy].
ui_web.UrlStrategy? get urlStrategy => _urlStrategy;

/// Change the strategy to use for handling browser URL.
///
/// Setting this to null disables all integration with the browser history.
void setUrlStrategy(ui_web.UrlStrategy? strategy) {
  _urlStrategy = strategy;
  ui_web.urlStrategy = strategy;
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
class HashUrlStrategy extends ui_web.UrlStrategy {
  /// Creates an instance of [HashUrlStrategy].
  ///
  /// The [PlatformLocation] parameter is useful for testing to mock out browser
  /// interactions.
  const HashUrlStrategy(
      [this._platformLocation = const BrowserPlatformLocation()]);

  final PlatformLocation _platformLocation;

  @override
  ui.VoidCallback addPopStateListener(ui_web.PopStateListener fn) {
    void wrappedFn(Object event) {
      // `fn` expects `event.state`, not a `web.Event`.
      fn((event as web.PopStateEvent).state);
    }
    _platformLocation.addPopStateListener(wrappedFn);
    return () => _platformLocation.removePopStateListener(wrappedFn);
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
    // when the hash path is empty, we still return the location's path and
    // query.
    return '${_platformLocation.pathname}${_platformLocation.search}'
        '${internalUrl.isEmpty ? '' : '#$internalUrl'}';
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
    super.platformLocation,
  ])  : _basePath = stripTrailingSlash(extractPathname(checkBaseHref(
          platformLocation.getBaseHref(),
        )));

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

final Map<EventListener, JSFunction> _listeners = <EventListener, JSFunction>{};

/// Delegates to real browser APIs to provide platform location functionality.
class BrowserPlatformLocation extends PlatformLocation {
  /// Default constructor for [BrowserPlatformLocation].
  const BrowserPlatformLocation();

  web.Location get _location => web.window.location;

  web.History get _history => web.window.history;

  @override
  void addPopStateListener(EventListener fn) {
    JSFunction? jsFn = _listeners[fn];
    if (jsFn == null) {
      jsFn = fn.toJS;
      _listeners[fn] = jsFn;
    }
    web.window.addEventListener('popstate'.toJS, jsFn);
  }

  @override
  void removePopStateListener(EventListener fn) {
    web.window.removeEventListener('popstate'.toJS, _listeners[fn]);
  }

  @override
  String get pathname => _location.pathname.toDart;

  @override
  String get search => _location.search.toDart;

  @override
  String get hash => _location.hash.toDart;

  @override
  Object? get state => _history.state;

  @override
  void pushState(Object? state, String title, String url) {
    _history.pushState(state?.toJS, title.toJS, url.toJS);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    _history.replaceState(state?.toJS, title.toJS, url.toJS);
  }

  @override
  void go(int count) {
    _history.go(count.toJS);
  }

  @override
  String? getBaseHref() => getBaseElementHrefFromDom();
}
