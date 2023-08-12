// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'platform.dart' as platform;

export 'platform.dart' show TargetPlatform;

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
    if (ui_web.debugEmulateFlutterTesterEnvironment) {
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
  final String navigatorPlatform = web.window.navigator.platform.toLowerCase();
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
  if (web.window.matchMedia('only screen and (pointer: fine)').matches) {
    return platform.TargetPlatform.linux;
  }
  return platform.TargetPlatform.android;
}();
