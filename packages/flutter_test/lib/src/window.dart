import 'dart:typed_data' show ByteData;
import 'dart:ui' hide window;

import 'package:meta/meta.dart';

/// [Window] that wraps another [Window] and allows faking of some properties
/// for testing purposes.
class TestWindow implements Window {
  /// Constructs a [TestWindow] that defers all behavior to the given [window] unless
  /// explicitly overidden for test purposes.
  TestWindow({
    @required Window window,
  }) : _window = window;

  /// The [Window] that is wrapped by this [TestWindow].
  final Window _window;

  @override
  double get devicePixelRatio => _devicePixelRatio ?? _window.devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatioTestValue(double devicePixelRatio) {
    _devicePixelRatio = devicePixelRatio;
  }
  void clearDevicePixelRatioTestValue() {
    _devicePixelRatio = null;
  }

  @override
  Size get physicalSize => _physicalSizeTestValue ?? _window.physicalSize;
  double _physicalSizeTestValue;
  set physicalSizeTestValue (double physicalSizeTestValue) {
    _physicalSizeTestValue = physicalSizeTestValue;
  }
  void clearPhysicalSizeTestValue() {
    _physicalSizeTestValue = null;
  }

  @override
  WindowPadding get viewInsets => _viewInsetsTestValue ??  _window.viewInsets;
  WindowPadding _viewInsetsTestValue;
  set viewInsetsTestValue(WindowPadding viewInsetsTestValue) {
    _viewInsetsTestValue = viewInsetsTestValue;
  }
  void clearViewInsetsTestValue() {
    _viewInsetsTestValue = null;
  }

  @override
  WindowPadding get padding => _paddingTestValue ?? _window.padding;
  WindowPadding _paddingTestValue;
  set paddingTestValue(WindowPadding paddingTestValue) {
    _paddingTestValue = paddingTestValue;
  }
  void clearPaddingTestValue() {
    _paddingTestValue = null;
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
  set localeTestValue(Locale localeTestValue) {
    _localeTestValue = localeTestValue;
  }
  void clearLocaleTestValue() {
    _localeTestValue = null;
  }

  @override
  List<Locale> get locales => _localesTestValue ?? _window.locales;
  List<Locale> _localesTestValue;
  set localesTestValue(List<Locale> localesTestValue) {
    _localesTestValue = localesTestValue;
  }
  void clearLocalesTestValue() {
    _localesTestValue = null;
  }

  @override
  VoidCallback get onLocaleChanged => _window.onLocaleChanged;
  @override
  set onLocaleChanged(VoidCallback callback) {
    _window.onLocaleChanged = callback;
  }

  @override
  double get textScaleFactor => _textScaleFactorTestValue ?? _window.textScaleFactor;
  double _textScaleFactorTestValue;
  set textScaleFactorTestValue(double textScaleFactorTestValue) {
    _textScaleFactorTestValue = textScaleFactorTestValue;
  }
  void clearTextScaleFactorTestValue() {
    _textScaleFactorTestValue = null;
  }

  @override
  bool get alwaysUse24HourFormat => _alwaysUse24HourFormatTestValue ?? _window.alwaysUse24HourFormat;
  bool _alwaysUse24HourFormatTestValue;
  set alwaysUse24HourFormatTestValue(bool alwaysUse24HourFormatTestValue) {
    _alwaysUse24HourFormatTestValue = alwaysUse24HourFormatTestValue;
  }
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
  PointerDataPacketCallback get onPointerDataPacket => _window.onPointerDataPacket;
  @override
  set onPointerDataPacket(PointerDataPacketCallback callback) {
    _window.onPointerDataPacket = callback;
  }

  @override
  String get defaultRouteName => _defaultRouteNameTestValue ?? _window.defaultRouteName;
  String _defaultRouteNameTestValue;
  set defaultRouteNameTestValue(String defaultRouteNameTestValue) {
    _defaultRouteNameTestValue = defaultRouteNameTestValue;
  }
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
  set semanticsEnabledTestValue(bool semanticsEnabledTestValue) {
    _semanticsEnabledTestValue = semanticsEnabledTestValue;
  }
  void clearSemanticsEnabledTestValue() {
    _semanticsEnabledTestValue = null;
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
  set accessibilityFeaturesTestValue(AccessibilityFeatures accessibilityFeaturesTestValue) {
    _accessibilityFeaturesTestValue = accessibilityFeaturesTestValue;
  }
  void clearAccessibilityFeaturesTestValue() {
    _accessibilityFeaturesTestValue = null;
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
  void sendPlatformMessage(String name,
                           ByteData data,
                           PlatformMessageResponseCallback callback) {
    _window.sendPlatformMessage(name, data, callback);
  }

  @override
  PlatformMessageCallback get onPlatformMessage => _window.onPlatformMessage;
  @override
  set onPlatformMessage(PlatformMessageCallback callback) {
    _window.onPlatformMessage = callback;
  }

}
