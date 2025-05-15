// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

extension SingletonFlutterWindowExtension on ui.SingletonFlutterWindow {
  /// Overrides the value of [physicalSize] in tests.
  set debugPhysicalSizeOverride(ui.Size? value) {
    (this as EngineFlutterWindow).debugPhysicalSizeOverride = value;
  }
}

/// Overrides the value of [ui.FlutterView.devicePixelRatio] in tests.
///
/// Passing `null` resets the device pixel ratio to the browser's default.
void debugOverrideDevicePixelRatio(double? value) {
  EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(value);
}

// /// Whether the Flutter engine is running in `flutter test` emulation mode.
// ///
// /// When true, the engine will emulate a specific screen size, and always
// /// use the "Ahem" font to reduce test flakiness and dependence on the test
// /// environment.
// bool get debugEmulateFlutterTesterEnvironment => _debugEmulateFlutterTesterEnvironment;

// /// Sets whether the Flutter engine is running in `flutter test` emulation mode.
// set debugEmulateFlutterTesterEnvironment(bool value) {
//   _debugEmulateFlutterTesterEnvironment = value;
//   if (_debugEmulateFlutterTesterEnvironment) {
//     const ui.Size logicalSize = ui.Size(800.0, 600.0);
//     final EngineFlutterWindow? implicitView = EnginePlatformDispatcher.instance.implicitView;
//     implicitView?.debugPhysicalSizeOverride = logicalSize * implicitView.devicePixelRatio;
//   }
//   debugDisableFontFallbacks = value;
// }

// bool _debugEmulateFlutterTesterEnvironment = false;

final class TestEnvironment {
  const TestEnvironment({
    this.ignorePlatformMessages = false,
    this.forceTestFonts = false,
    this.keepSemanticsDisabledOnUpdate = false,
    this.defaultToTestUrlStrategy = false,
  });

  const TestEnvironment.flutterTester()
    : ignorePlatformMessages = true,
      forceTestFonts = true,
      keepSemanticsDisabledOnUpdate = true,
      defaultToTestUrlStrategy = true;

  const TestEnvironment.production()
    : ignorePlatformMessages = false,
      forceTestFonts = false,
      keepSemanticsDisabledOnUpdate = false,
      defaultToTestUrlStrategy = false;

  static TestEnvironment? _instance;
  static TestEnvironment get instance {
    return _instance ??= const TestEnvironment.production();
  }

  static void setUp(TestEnvironment testEnvironment) {
    if (!kDebugMode) {
      throw UnsupportedError('`TestEnvironment.setUp` can only be used in debug mode.');
    }
    _instance = testEnvironment;
  }

  static void tearDown() {
    if (!kDebugMode) {
      throw UnsupportedError('`TestEnvironment.tearDown` can only be used in debug mode.');
    }
    _instance = null;
  }

  /// When true, the [ui.PlatformDispatcher] will ignore all platform messages.
  final bool ignorePlatformMessages;

  /// When true, all text will be laid out and rendered using test fonts.
  ///
  /// Only test fonts in [ui.TextStyle] and [ui.ParagraphStyle] will be respected. Any other fonts
  /// will be ignored.
  final bool forceTestFonts;

  /// When true, semantics will NOT be automatically enabled when a semantics update is received by
  /// [ui.FlutterView.updateSemantics].
  final bool keepSemanticsDisabledOnUpdate;

  /// When true, a [TestUrlStrategy] will be used instead of the default URL strategy.
  final bool defaultToTestUrlStrategy;
}
