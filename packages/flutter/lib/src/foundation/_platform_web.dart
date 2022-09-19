// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:js/js.dart';

import 'platform.dart' as platform;

export 'platform.dart' show TargetPlatform;

/// [DomWindow] interop object.
@JS()
@staticInterop
class DomWindow {}

/// [DomWindow] required extension.
extension DomWindowExtension on DomWindow {
  /// Returns a [DomMediaQueryList] of the media that matches [query].
  external DomMediaQueryList matchMedia(String? query);

  /// Returns the [DomNavigator] associated with this window.
  external DomNavigator get navigator;
}

/// The underyling window.
@JS('window')
external DomWindow get domWindow;

/// [DomMediaQueryList] interop object.
@JS()
@staticInterop
class DomMediaQueryList {}

/// [DomMediaQueryList] required extension.
extension DomMediaQueryListExtension on DomMediaQueryList {
  /// Whether or not the query matched.
  external bool get matches;
}

/// [DomNavigator] interop object.
@JS()
@staticInterop
class DomNavigator {}

/// [DomNavigator] required extension.
extension DomNavigatorExtension on DomNavigator {
  /// The underyling platform string.
  external String? get platform;
}

/// The web implementation of [platform.defaultTargetPlatform].
platform.TargetPlatform get defaultTargetPlatform {
  // To get a better guess at the targetPlatform we need to be able to reference
  // the window, but that won't be available until we fix the platforms
  // configuration for Flutter.
  return platform.debugDefaultTargetPlatformOverride ??
      _testPlatform ??
      _browserPlatform;
}

final platform.TargetPlatform? _testPlatform = () {
  platform.TargetPlatform? result;
  assert(() {
    // This member is only available in the web's dart:ui implementation.
    // ignore: undefined_prefixed_name
    if (ui.debugEmulateFlutterTesterEnvironment as bool) {
      result = platform.TargetPlatform.android;
    }
    return true;
  }());
  return result;
}();

// Lazy-initialized and forever cached current browser platform.
//
// Computing the platform is expensive as it uses `window.matchMedia`, which
// needs to parse and evaluate a CSS selector. On some devices this takes up to
// 0.20ms. As `defaultTargetPlatform` is routinely called dozens of times per
// frame this value should be cached.
final platform.TargetPlatform _browserPlatform = () {
  final String navigatorPlatform = domWindow.navigator.platform?.toLowerCase() ?? '';
  if (navigatorPlatform.startsWith('mac')) {
    return platform.TargetPlatform.macOS;
  }
  if (navigatorPlatform.startsWith('win')) {
    return platform.TargetPlatform.windows;
  }
  if (navigatorPlatform.contains('iphone') ||
      navigatorPlatform.contains('ipad') ||
      navigatorPlatform.contains('ipod')) {
    return platform.TargetPlatform.iOS;
  }
  if (navigatorPlatform.contains('android')) {
    return platform.TargetPlatform.android;
  }
  // Since some phones can report a window.navigator.platform as Linux, fall
  // back to use CSS to disambiguate Android vs Linux desktop. If the CSS
  // indicates that a device has a "fine pointer" (mouse) as the primary
  // pointing device, then we'll assume desktop linux, and otherwise we'll
  // assume Android.
  if (domWindow.matchMedia('only screen and (pointer: fine)').matches) {
    return platform.TargetPlatform.linux;
  }
  return platform.TargetPlatform.android;
}();
