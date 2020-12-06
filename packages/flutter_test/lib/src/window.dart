// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;
import 'dart:ui' hide window;

import 'package:meta/meta.dart';

/// [Window] that wraps another [Window] and allows faking of some properties
/// for testing purposes.
///
/// Tests for certain widgets, e.g., [MaterialApp], might require faking certain
/// properties of a [Window]. [TestWindow] facilitates the faking of these
/// properties by overriding the properties of a real [Window] with desired fake
/// values. The binding used within tests, [TestWidgetsFlutterBinding], contains
/// a [TestWindow] that is used by all tests.
///
/// ## Sample Code
///
/// A test can utilize a [TestWindow] in the following way:
///
/// ```dart
/// testWidgets('your test name here', (WidgetTester tester) async {
///   // Retrieve the TestWidgetsFlutterBinding.
///   final TestWidgetsFlutterBinding testBinding = tester.binding;
///
///   // Fake the desired properties of the TestWindow. All code running
///   // within this test will perceive the following fake text scale
///   // factor as the real text scale factor of the window.
///   testBinding.window.textScaleFactorFakeValue = 2.5;
///
///   // Test code that depends on text scale factor here.
/// });
/// ```
///
/// The [TestWidgetsFlutterBinding] is recreated for each test and
/// therefore any fake values defined in one test will not persist
/// to the next.
///
/// If a test needs to override a real [Window] property and then later
/// return to using the real [Window] property, [TestWindow] provides
/// methods to clear each individual test value, e.g., [clearLocaleTestValue()].
///
/// To clear all fake test values in a [TestWindow], consider using
/// [clearAllTestValues()].
class TestWindow implements Window {
  /// Constructs a [TestWindow] that defers all behavior to the given [Window]
  /// unless explicitly overridden for test purposes.
  TestWindow({
    @required Window window,
  }) : _window = window;

  /// The [Window] that is wrapped by this [TestWindow].
  final Window _window;

  @override
  double get devicePixelRatio => _devicePixelRatio ?? _window.devicePixelRatio;
  double _devicePixelRatio;
  /// Hides the real device pixel ratio and reports the given [devicePixelRatio]
  /// instead.
  set devicePixelRatioTestValue(double devicePixelRatio) {
    _devicePixelRatio = devicePixelRatio;
    onMetricsChanged();
  }
  /// Deletes any existing test device pixel ratio and returns to using the real
  /// device pixel ratio.
  void clearDevicePixelRatioTestValue() {
    _devicePixelRatio = null;
    onMetricsChanged();
  }

  @override
  Size get physicalSize => _physicalSizeTestValue ?? _window.physicalSize;
  Size _physicalSizeTestValue;
  /// Hides the real physical size and reports the given [physicalSizeTestValue]
  /// instead.
  set physicalSizeTestValue (Size physicalSizeTestValue) {
    _physicalSizeTestValue = physicalSizeTestValue;
    onMetricsChanged();
  }
  /// Deletes any existing test physical size and returns to using the real
  /// physical size.
  void clearPhysicalSizeTestValue() {
    _physicalSizeTestValue = null;
    onMetricsChanged();
  }

  @override
  WindowPadding get viewInsets => _viewInsetsTestValue ??  _window.viewInsets;
  WindowPadding _viewInsetsTestValue;
  /// Hides the real view insets and reports the given [viewInsetsTestValue]
  /// instead.
  set viewInsetsTestValue(WindowPadding viewInsetsTestValue) {
    _viewInsetsTestValue = viewInsetsTestValue;
    onMetricsChanged();
  }
  /// Deletes any existing test view insets and returns to using the real view
  /// insets.
  void clearViewInsetsTestValue() {
    _viewInsetsTestValue = null;
    onMetricsChanged();
  }

  @override
  WindowPadding get viewPadding => _viewPaddingTestValue ?? _window.padding;
  WindowPadding _viewPaddingTestValue;
  /// Hides the real view padding and reports the given [paddingTestValue]
  /// instead.
  set viewPaddingTestValue(WindowPadding viewPaddingTestValue) {
    _viewPaddingTestValue = viewPaddingTestValue;
    onMetricsChanged();
  }
  /// Deletes any existing test view padding and returns to using the real
  /// viewPadding.
  void clearViewPaddingTestValue() {
    _viewPaddingTestValue = null;
    onMetricsChanged();
  }

  @override
  WindowPadding get padding => _paddingTestValue ?? _window.padding;
  WindowPadding _paddingTestValue;
  /// Hides the real padding and reports the given [paddingTestValue] instead.
  set paddingTestValue(WindowPadding paddingTestValue) {
    _paddingTestValue = paddingTestValue;
    onMetricsChanged();
  }
  /// Deletes any existing test padding and returns to using the real padding.
  void clearPaddingTestValue() {
    _paddingTestValue = null;
    onMetricsChanged();
  }

  @override
  WindowPadding get systemGestureInsets => _systemGestureInsetsTestValue ?? _window.systemGestureInsets;
  WindowPadding _systemGestureInsetsTestValue;
  /// Hides the real system gesture insets and reports the given [systemGestureInsetsTestValue] instead.
  set systemGestureInsetsTestValue(WindowPadding systemGestureInsetsTestValue) {
    _systemGestureInsetsTestValue = systemGestureInsetsTestValue;
    onMetricsChanged();
  }
  /// Deletes any existing test system gesture insets and returns to using the real system gesture insets.
  void clearSystemGestureInsetsTestValue() {
    _systemGestureInsetsTestValue = null;
    onMetricsChanged();
  }

  @override
  VoidCallback get onMetricsChanged => _window.onMetricsChanged;
  @override
  set onMetricsChanged(VoidCallback callback) {
    _window.onMetricsChanged = callback;
  }

  @override
  Locale get locale => _localeTestValue ?? _window.locale;
  Locale _localeTestValue;
  /// Hides the real locale and reports the given [localeTestValue] instead.
  set localeTestValue(Locale localeTestValue) {
    _localeTestValue = localeTestValue;
    onLocaleChanged();
  }
  /// Deletes any existing test locale and returns to using the real locale.
  void clearLocaleTestValue() {
    _localeTestValue = null;
    onLocaleChanged();
  }

  @override
  List<Locale> get locales => _localesTestValue ?? _window.locales;
  List<Locale> _localesTestValue;
  /// Hides the real locales and reports the given [localesTestValue] instead.
  set localesTestValue(List<Locale> localesTestValue) {
    _localesTestValue = localesTestValue;
    onLocaleChanged();
  }
  /// Deletes any existing test locales and returns to using the real locales.
  void clearLocalesTestValue() {
    _localesTestValue = null;
    onLocaleChanged();
  }

  @override
  VoidCallback get onLocaleChanged => _window.onLocaleChanged;
  @override
  set onLocaleChanged(VoidCallback callback) {
    _window.onLocaleChanged = callback;
  }

  @override
  String get initialLifecycleState => _initialLifecycleStateTestValue;
  String _initialLifecycleStateTestValue = '';
  /// Sets a faked initialLifecycleState for testing.
  set initialLifecycleStateTestValue(String state) {
    _initialLifecycleStateTestValue = state;
  }

  @override
  double get textScaleFactor => _textScaleFactorTestValue ?? _window.textScaleFactor;
  double _textScaleFactorTestValue;
  /// Hides the real text scale factor and reports the given
  /// [textScaleFactorTestValue] instead.
  set textScaleFactorTestValue(double textScaleFactorTestValue) {
    _textScaleFactorTestValue = textScaleFactorTestValue;
    onTextScaleFactorChanged();
  }
  /// Deletes any existing test text scale factor and returns to using the real
  /// text scale factor.
  void clearTextScaleFactorTestValue() {
    _textScaleFactorTestValue = null;
    onTextScaleFactorChanged();
  }

  @override
  Brightness get platformBrightness => _platformBrightnessTestValue ?? _window.platformBrightness;
  Brightness _platformBrightnessTestValue;
  @override
  VoidCallback get onPlatformBrightnessChanged => _window.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(VoidCallback callback) {
    _window.onPlatformBrightnessChanged = callback;
  }
  /// Hides the real text scale factor and reports the given
  /// [platformBrightnessTestValue] instead.
  set platformBrightnessTestValue(Brightness platformBrightnessTestValue) {
    _platformBrightnessTestValue = platformBrightnessTestValue;
    onPlatformBrightnessChanged();
  }
  /// Deletes any existing test platform brightness and returns to using the
  /// real platform brightness.
  void clearPlatformBrightnessTestValue() {
    _platformBrightnessTestValue = null;
    onPlatformBrightnessChanged();
  }

  @override
  bool get alwaysUse24HourFormat => _alwaysUse24HourFormatTestValue ?? _window.alwaysUse24HourFormat;
  bool _alwaysUse24HourFormatTestValue;
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
  VoidCallback get onTextScaleFactorChanged => _window.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(VoidCallback callback) {
    _window.onTextScaleFactorChanged = callback;
  }

  @override
  FrameCallback get onBeginFrame => _window.onBeginFrame;
  @override
  set onBeginFrame(FrameCallback callback) {
    _window.onBeginFrame = callback;
  }

  @override
  VoidCallback get onDrawFrame => _window.onDrawFrame;
  @override
  set onDrawFrame(VoidCallback callback) {
    _window.onDrawFrame = callback;
  }

  @override
  TimingsCallback get onReportTimings => _window.onReportTimings;
  @override
  set onReportTimings(TimingsCallback callback) {
    _window.onReportTimings = callback;
  }

  @override
  PointerDataPacketCallback get onPointerDataPacket => _window.onPointerDataPacket;
  @override
  set onPointerDataPacket(PointerDataPacketCallback callback) {
    _window.onPointerDataPacket = callback;
  }

  @override
  String get defaultRouteName => _defaultRouteNameTestValue ?? _window.defaultRouteName;
  String _defaultRouteNameTestValue;
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
    _window.scheduleFrame();
  }

  @override
  void render(Scene scene) {
    _window.render(scene);
  }

  @override
  bool get semanticsEnabled => _semanticsEnabledTestValue ?? _window.semanticsEnabled;
  bool _semanticsEnabledTestValue;
  /// Hides the real semantics enabled and reports the given
  /// [semanticsEnabledTestValue] instead.
  set semanticsEnabledTestValue(bool semanticsEnabledTestValue) {
    _semanticsEnabledTestValue = semanticsEnabledTestValue;
    onSemanticsEnabledChanged();
  }
  /// Deletes any existing test semantics enabled and returns to using the real
  /// semantics enabled.
  void clearSemanticsEnabledTestValue() {
    _semanticsEnabledTestValue = null;
    onSemanticsEnabledChanged();
  }

  @override
  VoidCallback get onSemanticsEnabledChanged => _window.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(VoidCallback callback) {
    _window.onSemanticsEnabledChanged = callback;
  }

  @override
  SemanticsActionCallback get onSemanticsAction => _window.onSemanticsAction;
  @override
  set onSemanticsAction(SemanticsActionCallback callback) {
    _window.onSemanticsAction = callback;
  }

  @override
  AccessibilityFeatures get accessibilityFeatures => _accessibilityFeaturesTestValue ?? _window.accessibilityFeatures;
  AccessibilityFeatures _accessibilityFeaturesTestValue;
  /// Hides the real accessibility features and reports the given
  /// [accessibilityFeaturesTestValue] instead.
  set accessibilityFeaturesTestValue(AccessibilityFeatures accessibilityFeaturesTestValue) {
    _accessibilityFeaturesTestValue = accessibilityFeaturesTestValue;
    onAccessibilityFeaturesChanged();
  }
  /// Deletes any existing test accessibility features and returns to using the
  /// real accessibility features.
  void clearAccessibilityFeaturesTestValue() {
    _accessibilityFeaturesTestValue = null;
    onAccessibilityFeaturesChanged();
  }

  @override
  VoidCallback get onAccessibilityFeaturesChanged => _window.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(VoidCallback callback) {
    _window.onAccessibilityFeaturesChanged = callback;
  }

  @override
  void updateSemantics(SemanticsUpdate update) {
    _window.updateSemantics(update);
  }

  @override
  void setIsolateDebugName(String name) {
    _window.setIsolateDebugName(name);
  }

  @override
  void sendPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {
    _window.sendPlatformMessage(name, data, callback);
  }

  @override
  PlatformMessageCallback get onPlatformMessage => _window.onPlatformMessage;
  @override
  set onPlatformMessage(PlatformMessageCallback callback) {
    _window.onPlatformMessage = callback;
  }

  /// Delete any test value properties that have been set on this [TestWindow]
  /// and return to reporting the real [Window] values for all [Window]
  /// properties.
  ///
  /// If desired, clearing of properties can be done on an individual basis,
  /// e.g., [clearLocaleTestValue()].
  void clearAllTestValues() {
    clearAccessibilityFeaturesTestValue();
    clearAlwaysUse24HourTestValue();
    clearDefaultRouteNameTestValue();
    clearDevicePixelRatioTestValue();
    clearPlatformBrightnessTestValue();
    clearLocaleTestValue();
    clearLocalesTestValue();
    clearPaddingTestValue();
    clearPhysicalSizeTestValue();
    clearSemanticsEnabledTestValue();
    clearTextScaleFactorTestValue();
    clearViewInsetsTestValue();
  }

  /// This gives us some grace time when the dart:ui side adds something to
  /// Window, and makes things easier when we do rolls to give us time to catch
  /// up.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
