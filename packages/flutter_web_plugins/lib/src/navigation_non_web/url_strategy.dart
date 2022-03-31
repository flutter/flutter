// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import '../navigation_common/url_strategy.dart';

/// Returns the present [UrlStrategy] for handling the browser URL.
///
/// In case null is returned, the browser integration has been manually
/// disabled by [setUrlStrategy].
UrlStrategy? get urlStrategy => null;

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
  const HashUrlStrategy([PlatformLocation? _]);

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
  void pushState(Object? state, String title, String url) {
    // No-op.
  }

  @override
  void replaceState(Object? state, String title, String url) {
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
  PathUrlStrategy([super.platformLocation]);

  @override
  String getPath() => '';

  @override
  String prepareExternalUrl(String internalUrl) => '';
}
