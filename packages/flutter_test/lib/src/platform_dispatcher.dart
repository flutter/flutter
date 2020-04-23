// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;
import 'dart:ui';

import 'package:meta/meta.dart';

/// [PlatformDispatcher] that wraps another [PlatformDispatcher] and allows faking of some properties
/// for testing purposes.
///
/// Tests for certain widgets, e.g., [MaterialApp], might require faking certain
/// properties of a [PlatformDispatcher]. [TestPlatformDispatcher] facilitates the faking of these
/// properties by overriding the properties of a real [PlatformDispatcher] with desired fake
/// values. The binding used within tests, [TestWidgetsFlutterBinding], contains
/// a [TestPlatformDispatcher] that is used by all tests.
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
///   // Fake the desired properties of the TestPlatformDispatcher. All code running
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
/// If a test needs to override a real [PlatformDispatcher] property and then later
/// return to using the real [PlatformDispatcher] property, [TestPlatformDispatcher] provides
/// methods to clear each individual test value, e.g., [clearLocaleTestValue()].
///
/// To clear all fake test values in a [TestPlatformDispatcher], consider using
/// [clearAllTestValues()].
class TestPlatformDispatcher implements PlatformDispatcher {
  /// Constructs a [TestPlatformDispatcher] that defers all behavior to the given [PlatformDispatcher]
  /// unless explicitly overridden for test purposes.
  TestPlatformDispatcher({
    @required PlatformDispatcher platformDispatcher,
  }) : _platformDispatcher = platformDispatcher;

  /// The [PlatformDispatcher] that is used by this [TestPlatformDispatcher].
  final PlatformDispatcher _platformDispatcher;

  /// The current platform configuration.
  @override
  PlatformConfiguration get configuration => _platformDispatcher.configuration;

  /// The current list of screens.
  @override
  Iterable<Screen> get screens => _platformDispatcher.screens;

  /// The current list of windows,
  @override
  Iterable<FlutterView> get views => _platformDispatcher.views;

  /// Receives all events related to platform configuration changes.
  @override
  VoidCallback get onPlatformConfigurationChanged => _platformDispatcher.onPlatformConfigurationChanged;
  @override
  set onPlatformConfigurationChanged(VoidCallback callback) {
    _platformDispatcher.onPlatformConfigurationChanged = callback;
  }

  /// Is called when [openWindow] is called.
  ///
  /// Sends the opaque ID of the newly opened window.
  @override
  ViewCreatedCallback get onViewCreated => _platformDispatcher.onViewCreated;
  @override
  set onViewCreated(ViewCreatedCallback callback) {
    _platformDispatcher.onViewCreated = callback;
  }

  /// Is called when a window closure is requested by the platform.
  ///
  /// Sends the opaque ID of the window to be closed.
  @override
  ViewDisposedCallback get onViewDisposed => _platformDispatcher.onViewDisposed;
  @override
  set onViewDisposed(ViewDisposedCallback callback) {
    _platformDispatcher.onViewDisposed = callback;
  }

  /// A callback invoked when any window begins a frame.
  ///
  /// {@template flutter.foundation.PlatformDispatcher.onBeginFrame}
  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [PlatformWindow.render] method.
  /// When possible, this is driven by the hardware VSync signal of the attached
  /// screen with the highest VSync rate. This is only called if
  /// [PlatformWindow.scheduleFrame] has been called since the last time this
  /// callback was invoked.
  /// {@endtemplate}
  @override
  FrameCallback get onBeginFrame => _platformDispatcher.onBeginFrame;
  @override
  set onBeginFrame(FrameCallback callback) {
    _platformDispatcher.onBeginFrame = callback;
  }

  /// {@template flutter.foundation.PlatformDispatcher.onDrawFrame}
  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained.
  ///
  /// This can be used to implement a second phase of frame rendering that
  /// happens after any deferred work queued by the [onBeginFrame] phase.
  /// {@endtemplate}
  @override
  VoidCallback get onDrawFrame => _platformDispatcher.onDrawFrame;
  @override
  set onDrawFrame(VoidCallback callback) {
    _platformDispatcher.onDrawFrame = callback;
  }

  /// A callback that is invoked when pointer data is available.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  @override
  PointerDataPacketCallback get onPointerDataPacket => _platformDispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(PointerDataPacketCallback callback) {
    _platformDispatcher.onPointerDataPacket = callback;
  }

  @override
  Locale get locale => _localeTestValue ?? _platformDispatcher.locale;
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
  List<Locale> get locales => _localesTestValue ?? _platformDispatcher.locales;
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
  VoidCallback get onLocaleChanged => _platformDispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(VoidCallback callback) {
    _platformDispatcher.onLocaleChanged = callback;
  }

  @override
  String get initialLifecycleState => _initialLifecycleStateTestValue;
  String _initialLifecycleStateTestValue;
  /// Sets a faked initialLifecycleState for testing.
  set initialLifecycleStateTestValue(String state) {
    _initialLifecycleStateTestValue = state;
  }

  @override
  double get textScaleFactor => _textScaleFactorTestValue ?? _platformDispatcher.textScaleFactor;
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
  Brightness get platformBrightness => _platformBrightnessTestValue ?? _platformDispatcher.platformBrightness;
  Brightness _platformBrightnessTestValue;
  @override
  VoidCallback get onPlatformBrightnessChanged => _platformDispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(VoidCallback callback) {
    _platformDispatcher.onPlatformBrightnessChanged = callback;
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
  bool get alwaysUse24HourFormat => _alwaysUse24HourFormatTestValue ?? _platformDispatcher.alwaysUse24HourFormat;
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
  VoidCallback get onTextScaleFactorChanged => _platformDispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(VoidCallback callback) {
    _platformDispatcher.onTextScaleFactorChanged = callback;
  }

  @override
  TimingsCallback get onReportTimings => _platformDispatcher.onReportTimings;
  @override
  set onReportTimings(TimingsCallback callback) {
    _platformDispatcher.onReportTimings = callback;
  }

  @override
  String get initialRouteName => _initialRouteNameTestValue ?? _platformDispatcher.initialRouteName;
  String _initialRouteNameTestValue;
  /// Hides the real default route name and reports the given
  /// [initialRouteNameTestValue] instead.
  set initialRouteNameTestValue(String initialRouteNameTestValue) {
    _initialRouteNameTestValue = initialRouteNameTestValue;
  }
  /// Deletes any existing test default route name and returns to using the real
  /// default route name.
  void clearDefaultRouteNameTestValue() {
    _initialRouteNameTestValue = null;
  }

  @override
  void scheduleFrame() {
    _platformDispatcher.scheduleFrame();
  }

  @override
  void render(Scene scene, [FlutterView view]) {
    _platformDispatcher.render(scene, view);
  }

  @override
  bool get semanticsEnabled => _semanticsEnabledTestValue ?? _platformDispatcher.semanticsEnabled;
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
  VoidCallback get onSemanticsEnabledChanged => _platformDispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(VoidCallback callback) {
    _platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  @override
  SemanticsActionCallback get onSemanticsAction => _platformDispatcher.onSemanticsAction;
  @override
  set onSemanticsAction(SemanticsActionCallback callback) {
    _platformDispatcher.onSemanticsAction = callback;
  }

  @override
  AccessibilityFeatures get accessibilityFeatures => _accessibilityFeaturesTestValue ?? _platformDispatcher.accessibilityFeatures;
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
  VoidCallback get onAccessibilityFeaturesChanged => _platformDispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(VoidCallback callback) {
    _platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  @override
  void updateSemantics(SemanticsUpdate update) {
    _platformDispatcher.updateSemantics(update);
  }

  @override
  void setIsolateDebugName(String name) {
    _platformDispatcher.setIsolateDebugName(name);
  }

  @override
  void sendPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {
    _platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  @override
  PlatformMessageCallback get onPlatformMessage => _platformDispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(PlatformMessageCallback callback) {
    _platformDispatcher.onPlatformMessage = callback;
  }

  /// Delete any test value properties that have been set on this [TestPlatformDispatcher]
  /// and return to reporting the real [PlatformDispatcher] values for all [PlatformDispatcher]
  /// properties.
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
  /// PlatformDispatcher, and makes things easier when we do rolls to give us time to catch
  /// up.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
