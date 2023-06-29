// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Whether the Flutter engine is running in `flutter test` emulation mode.
///
/// When true, the engine will emulate a specific screen size, and always
/// use the "Ahem" font to reduce test flakiness and dependence on the test
/// environment.
bool get debugEmulateFlutterTesterEnvironment =>
    _debugEmulateFlutterTesterEnvironment;

/// Sets whether the Flutter engine is running in `flutter test` emulation mode.
set debugEmulateFlutterTesterEnvironment(bool value) {
  _debugEmulateFlutterTesterEnvironment = value;
  if (_debugEmulateFlutterTesterEnvironment) {
    const ui.Size logicalSize = ui.Size(800.0, 600.0);
    window.webOnlyDebugPhysicalSizeOverride =
        logicalSize * window.devicePixelRatio;
  }
  debugDisableFontFallbacks = value;
}

bool _debugEmulateFlutterTesterEnvironment = false;
