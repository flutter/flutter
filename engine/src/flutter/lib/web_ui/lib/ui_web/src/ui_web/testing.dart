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

final class TestEnvironment {
  const TestEnvironment({
    this.ignorePlatformMessages = false,
    this.forceTestFonts = false,
    this.disableFontFallbacks = false,
    this.keepSemanticsDisabledOnUpdate = false,
    this.defaultToTestUrlStrategy = false,
  });

  const TestEnvironment.flutterTester()
    : ignorePlatformMessages = true,
      forceTestFonts = true,
      disableFontFallbacks = true,
      keepSemanticsDisabledOnUpdate = true,
      defaultToTestUrlStrategy = true;

  const TestEnvironment.production() : this();

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

  /// When true, the font fallback system will be disabled.
  ///
  /// We need to disable font fallbacks for some framework tests because
  /// Flutter error messages may contain an arrow symbol which is not
  /// covered by ASCII fonts. This causes us to try to download the
  /// Noto Sans Symbols font, which kicks off a `Timer` which doesn't
  /// complete before the Widget tree is disposed (this is by design).
  final bool disableFontFallbacks;

  /// When true, semantics will NOT be automatically enabled when a semantics update is received by
  /// [ui.FlutterView.updateSemantics].
  final bool keepSemanticsDisabledOnUpdate;

  /// When true, a [TestUrlStrategy] will be used instead of the default URL strategy.
  final bool defaultToTestUrlStrategy;
}
