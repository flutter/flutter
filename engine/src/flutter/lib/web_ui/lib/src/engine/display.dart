// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../engine.dart';

class EngineFlutterDisplay extends ui.Display {
  EngineFlutterDisplay({
    required this.id,
    required this.size,
    required this.refreshRate,
  });

  /// The single [EngineFlutterDisplay] that the web page is rendered on.
  static EngineFlutterDisplay get instance => _instance;
  static final EngineFlutterDisplay _instance = EngineFlutterDisplay(
    id: 0,
    size: ui.Size(domWindow.screen?.width ?? 0, domWindow.screen?.height ?? 0),
    refreshRate: 60,
  );

  @override
  final int id;

  // TODO(mdebbar): https://github.com/flutter/flutter/issues/133562
  // `size` and `refreshRate` should be kept up-to-date with the
  // browser. E.g. the window could be resized or moved to another display with
  // a different refresh rate.

  @override
  final ui.Size size;

  @override
  final double refreshRate;

  @override
  double get devicePixelRatio =>
      _debugDevicePixelRatioOverride ?? browserDevicePixelRatio;

  /// The real device pixel ratio of the browser.
  ///
  /// This value cannot be overriden by tests, for example.
  double get browserDevicePixelRatio {
    final double ratio = domWindow.devicePixelRatio;
    // Guard against WebOS returning 0.
    return (ratio == 0.0) ? 1.0 : ratio;
  }

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  ///
  /// Passing `null` resets the device pixel ratio to the browser's default.
  void debugOverrideDevicePixelRatio(double? value) {
    _debugDevicePixelRatioOverride = value;
  }

  double? _debugDevicePixelRatioOverride;
}
