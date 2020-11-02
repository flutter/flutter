// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

/// [dart:ui.PlatformDispatcher] that wraps another [dart:ui.PlatformDispatcher]
/// and allows faking of some properties for testing purposes.
///
/// Tests for certain widgets, e.g., [MaterialApp], might require faking certain
/// properties of a [PlatformDispatcher]. [TestPlatformDispatcher] facilitates
/// the faking of these properties by overriding the properties of a real
/// [PlatformDispatcher] with desired fake values. The binding used within
/// tests, [TestWidgetsFlutterBinding], contains a [TestPlatformDispatcher] that
/// is used by all tests.
///
/// ## Sample Code
///
/// A test can utilize a [TestPlatformDispatcher] in the following way:
///
/// ```dart
/// testWidgets('your test name here', (WidgetTester tester) async {
///   // Retrieve the TestWidgetsFlutterBinding.
///   final TestWidgetsFlutterBinding testBinding = tester.binding;
///
///   // Fake the desired properties of the TestPlatformDispatcher. All code
///   //  running within this test will perceive the following fake text scale
///   // factor as the real text scale factor of the window.
///   testBinding.platformDispatcher.textScaleFactorFakeValue = 2.5;
///
///   // Test code that depends on text scale factor here.
/// });
/// ```
///
/// The [TestWidgetsFlutterBinding] is recreated for each test and
/// therefore any fake values defined in one test will not persist
/// to the next.
///
/// If a test needs to override a real [PlatformDispatcher] property and then
/// later return to using the real [PlatformDispatcher] property,
/// [TestPlatformDispatcher] provides methods to clear each individual test
/// value, e.g., [clearLocaleTestValue()].
///
/// To clear all fake test values in a [TestPlatformDispatcher], consider using
/// [clearAllTestValues()].
class TestPlatformDispatcher implements ui.PlatformDispatcher {
  /// Constructs a [TestPlatformDispatcher] that defers all behavior to the given
  /// [dart:ui.PlatformDispatcher] unless explicitly overridden for test purposes.
  TestPlatformDispatcher({
    required ui.PlatformDispatcher platformDispatcher,
  }) : _platformDispatcher = platformDispatcher;

  /// The [dart:ui.PlatformDispatcher] that is wrapped by this [TestPlatformDispatcher].
  final ui.PlatformDispatcher _platformDispatcher;

  @override
  ui.VoidCallback? get onMetricsChanged => _platformDispatcher.onMetricsChanged;
  @override
  set onMetricsChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onMetricsChanged = callback;
  }

  @override
  ui.Locale? get locale => _localeTestValue ?? _platformDispatcher.locale;
  ui.Locale? _localeTestValue;
  /// Hides the real locale and reports the given [localeTestValue] instead.
  set localeTestValue(ui.Locale localeTestValue) {
    _localeTestValue = localeTestValue;
    onLocaleChanged?.call();
  }
  /// Deletes any existing test locale and returns to using the real locale.
  void clearLocaleTestValue() {
    _localeTestValue = null;
    onLocaleChanged?.call();
  }

  @override
  List<ui.Locale>? get locales => _localesTestValue ?? _platformDispatcher.locales;
  List<ui.Locale>? _localesTestValue;
  /// Hides the real locales and reports the given [localesTestValue] instead.
  set localesTestValue(List<ui.Locale> localesTestValue) {
    _localesTestValue = localesTestValue;
    onLocaleChanged?.call();
  }
  /// Deletes any existing test locales and returns to using the real locales.
  void clearLocalesTestValue() {
    _localesTestValue = null;
    onLocaleChanged?.call();
  }

  @override
  ui.VoidCallback? get onLocaleChanged => _platformDispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onLocaleChanged = callback;
  }

  @override
  String get initialLifecycleState => _initialLifecycleStateTestValue;
  String _initialLifecycleStateTestValue = '';
  /// Sets a faked initialLifecycleState for testing.
  set initialLifecycleStateTestValue(String state) {
    _initialLifecycleStateTestValue = state;
  }

  @override
  double get textScaleFactor => _textScaleFactorTestValue ?? _platformDispatcher.textScaleFactor;
  double? _textScaleFactorTestValue;
  /// Hides the real text scale factor and reports the given
  /// [textScaleFactorTestValue] instead.
  set textScaleFactorTestValue(double textScaleFactorTestValue) {
    _textScaleFactorTestValue = textScaleFactorTestValue;
    onTextScaleFactorChanged?.call();
  }
  /// Deletes any existing test text scale factor and returns to using the real
  /// text scale factor.
  void clearTextScaleFactorTestValue() {
    _textScaleFactorTestValue = null;
    onTextScaleFactorChanged?.call();
  }

  @override
  ui.Brightness get platformBrightness => _platformBrightnessTestValue ?? _platformDispatcher.platformBrightness;
  ui.Brightness? _platformBrightnessTestValue;
  @override
  ui.VoidCallback? get onPlatformBrightnessChanged => _platformDispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onPlatformBrightnessChanged = callback;
  }
  /// Hides the real text scale factor and reports the given
  /// [platformBrightnessTestValue] instead.
  set platformBrightnessTestValue(ui.Brightness platformBrightnessTestValue) {
    _platformBrightnessTestValue = platformBrightnessTestValue;
    onPlatformBrightnessChanged?.call();
  }
  /// Deletes any existing test platform brightness and returns to using the
  /// real platform brightness.
  void clearPlatformBrightnessTestValue() {
    _platformBrightnessTestValue = null;
    onPlatformBrightnessChanged?.call();
  }

  @override
  bool get alwaysUse24HourFormat => _alwaysUse24HourFormatTestValue ?? _platformDispatcher.alwaysUse24HourFormat;
  bool? _alwaysUse24HourFormatTestValue;
  /// Hides the real clock format and reports the given
  /// [alwaysUse24HourFormatTestValue] instead.
  set alwaysUse24HourFormatTestValue(bool alwaysUse24HourFormatTestValue) {
    _alwaysUse24HourFormatTestValue = alwaysUse24HourFormatTestValue;
  }
  /// Deletes any existing test clock format and returns to using the real clock
  /// format.
  void clearAlwaysUse24HourTestValue() {
    _alwaysUse24HourFormatTestValue = null;
  }

  @override
  ui.VoidCallback? get onTextScaleFactorChanged => _platformDispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onTextScaleFactorChanged = callback;
  }

  @override
  ui.FrameCallback? get onBeginFrame => _platformDispatcher.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? callback) {
    _platformDispatcher.onBeginFrame = callback;
  }

  @override
  ui.VoidCallback? get onDrawFrame => _platformDispatcher.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? callback) {
    _platformDispatcher.onDrawFrame = callback;
  }

  @override
  ui.TimingsCallback? get onReportTimings => _platformDispatcher.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? callback) {
    _platformDispatcher.onReportTimings = callback;
  }

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket => _platformDispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? callback) {
    _platformDispatcher.onPointerDataPacket = callback;
  }

  @override
  String get defaultRouteName => _defaultRouteNameTestValue ?? _platformDispatcher.defaultRouteName;
  String? _defaultRouteNameTestValue;
  /// Hides the real default route name and reports the given
  /// [defaultRouteNameTestValue] instead.
  set defaultRouteNameTestValue(String defaultRouteNameTestValue) {
    _defaultRouteNameTestValue = defaultRouteNameTestValue;
  }
  /// Deletes any existing test default route name and returns to using the real
  /// default route name.
  void clearDefaultRouteNameTestValue() {
    _defaultRouteNameTestValue = null;
  }

  @override
  void scheduleFrame() {
    _platformDispatcher.scheduleFrame();
  }

  @override
  bool get semanticsEnabled => _semanticsEnabledTestValue ?? _platformDispatcher.semanticsEnabled;
  bool? _semanticsEnabledTestValue;
  /// Hides the real semantics enabled and reports the given
  /// [semanticsEnabledTestValue] instead.
  set semanticsEnabledTestValue(bool semanticsEnabledTestValue) {
    _semanticsEnabledTestValue = semanticsEnabledTestValue;
    onSemanticsEnabledChanged?.call();
  }
  /// Deletes any existing test semantics enabled and returns to using the real
  /// semantics enabled.
  void clearSemanticsEnabledTestValue() {
    _semanticsEnabledTestValue = null;
    onSemanticsEnabledChanged?.call();
  }

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged => _platformDispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  @override
  ui.SemanticsActionCallback? get onSemanticsAction => _platformDispatcher.onSemanticsAction;
  @override
  set onSemanticsAction(ui.SemanticsActionCallback? callback) {
    _platformDispatcher.onSemanticsAction = callback;
  }

  @override
  ui.AccessibilityFeatures get accessibilityFeatures => _accessibilityFeaturesTestValue ?? _platformDispatcher.accessibilityFeatures;
  ui.AccessibilityFeatures? _accessibilityFeaturesTestValue;
  /// Hides the real accessibility features and reports the given
  /// [accessibilityFeaturesTestValue] instead.
  set accessibilityFeaturesTestValue(ui.AccessibilityFeatures accessibilityFeaturesTestValue) {
    _accessibilityFeaturesTestValue = accessibilityFeaturesTestValue;
    onAccessibilityFeaturesChanged?.call();
  }
  /// Deletes any existing test accessibility features and returns to using the
  /// real accessibility features.
  void clearAccessibilityFeaturesTestValue() {
    _accessibilityFeaturesTestValue = null;
    onAccessibilityFeaturesChanged?.call();
  }

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged => _platformDispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? callback) {
    _platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  @override
  void updateSemantics(ui.SemanticsUpdate update) {
    _platformDispatcher.updateSemantics(update);
  }

  @override
  void setIsolateDebugName(String name) {
    _platformDispatcher.setIsolateDebugName(name);
  }

  @override
  void sendPlatformMessage(
      String name,
      ByteData? data,
      ui.PlatformMessageResponseCallback? callback,
      ) {
    _platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  @override
  ui.PlatformMessageCallback? get onPlatformMessage => _platformDispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(ui.PlatformMessageCallback? callback) {
    _platformDispatcher.onPlatformMessage = callback;
  }

  /// Delete any test value properties that have been set on this [TestPlatformDispatcher]
  /// and return to reporting the real [PlatformDispatcher] values for all
  /// [PlatformDispatcher] properties.
  ///
  /// If desired, clearing of properties can be done on an individual basis,
  /// e.g., [clearLocaleTestValue()].
  void clearAllTestValues() {
    clearAccessibilityFeaturesTestValue();
    clearAlwaysUse24HourTestValue();
    clearDefaultRouteNameTestValue();
    clearPlatformBrightnessTestValue();
    clearLocaleTestValue();
    clearLocalesTestValue();
    clearSemanticsEnabledTestValue();
    clearTextScaleFactorTestValue();
  }

  /// This gives us some grace time when the dart:ui side adds something to
  /// Window, and makes things easier when we do rolls to give us time to catch
  /// up.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
