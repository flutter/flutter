// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

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

// Current browser platform.
//
// Lazy-initialized and forever cached as `defaultTargetPlatform` is routinely
// called dozens of times per frame.
final platform.TargetPlatform _browserPlatform = () {
  return switch (ui_web.browser.operatingSystem) {
    ui_web.OperatingSystem.android => platform.TargetPlatform.android,
    ui_web.OperatingSystem.iOs => platform.TargetPlatform.iOS,
    ui_web.OperatingSystem.linux => platform.TargetPlatform.linux,
    ui_web.OperatingSystem.macOs => platform.TargetPlatform.macOS,
    ui_web.OperatingSystem.windows => platform.TargetPlatform.windows,
    // Default 'unknown' OS values to `android`.
    _ => platform.TargetPlatform.android,
  };
}();
