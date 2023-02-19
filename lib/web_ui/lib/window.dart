// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

abstract class FlutterView {
  PlatformDispatcher get platformDispatcher;
  ViewConfiguration get viewConfiguration;
  Object get viewId;
  double get devicePixelRatio => viewConfiguration.devicePixelRatio;
  Rect get physicalGeometry => viewConfiguration.geometry;
  Size get physicalSize => viewConfiguration.geometry.size;
  ViewPadding get viewInsets => viewConfiguration.viewInsets;
  ViewPadding get viewPadding => viewConfiguration.viewPadding;
  ViewPadding get systemGestureInsets => viewConfiguration.systemGestureInsets;
  ViewPadding get padding => viewConfiguration.padding;
  List<DisplayFeature> get displayFeatures => viewConfiguration.displayFeatures;
  void render(Scene scene) => platformDispatcher.render(scene, this);
  void updateSemantics(SemanticsUpdate update) => platformDispatcher.updateSemantics(update);
}

abstract class SingletonFlutterWindow extends FlutterView {
  VoidCallback? get onMetricsChanged => platformDispatcher.onMetricsChanged;
  set onMetricsChanged(VoidCallback? callback) {
    platformDispatcher.onMetricsChanged = callback;
  }

  Locale get locale => platformDispatcher.locale;
  List<Locale> get locales => platformDispatcher.locales;

  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    return platformDispatcher.computePlatformResolvedLocale(supportedLocales);
  }

  VoidCallback? get onLocaleChanged => platformDispatcher.onLocaleChanged;
  set onLocaleChanged(VoidCallback? callback) {
    platformDispatcher.onLocaleChanged = callback;
  }

  String get initialLifecycleState => platformDispatcher.initialLifecycleState;

  double get textScaleFactor => platformDispatcher.textScaleFactor;

  bool get nativeSpellCheckServiceDefined => platformDispatcher.nativeSpellCheckServiceDefined;

  bool get brieflyShowPassword => platformDispatcher.brieflyShowPassword;

  bool get alwaysUse24HourFormat => platformDispatcher.alwaysUse24HourFormat;

  VoidCallback? get onTextScaleFactorChanged => platformDispatcher.onTextScaleFactorChanged;
  set onTextScaleFactorChanged(VoidCallback? callback) {
    platformDispatcher.onTextScaleFactorChanged = callback;
  }

  Brightness get platformBrightness => platformDispatcher.platformBrightness;

  VoidCallback? get onPlatformBrightnessChanged => platformDispatcher.onPlatformBrightnessChanged;
  set onPlatformBrightnessChanged(VoidCallback? callback) {
    platformDispatcher.onPlatformBrightnessChanged = callback;
  }

  String? get systemFontFamily => platformDispatcher.systemFontFamily;

  VoidCallback? get onSystemFontFamilyChanged => platformDispatcher.onSystemFontFamilyChanged;
  set onSystemFontFamilyChanged(VoidCallback? callback) {
    platformDispatcher.onSystemFontFamilyChanged = callback;
  }

  FrameCallback? get onBeginFrame => platformDispatcher.onBeginFrame;
  set onBeginFrame(FrameCallback? callback) {
    platformDispatcher.onBeginFrame = callback;
  }

  VoidCallback? get onDrawFrame => platformDispatcher.onDrawFrame;
  set onDrawFrame(VoidCallback? callback) {
    platformDispatcher.onDrawFrame = callback;
  }

  TimingsCallback? get onReportTimings => platformDispatcher.onReportTimings;
  set onReportTimings(TimingsCallback? callback) {
    platformDispatcher.onReportTimings = callback;
  }

  PointerDataPacketCallback? get onPointerDataPacket => platformDispatcher.onPointerDataPacket;
  set onPointerDataPacket(PointerDataPacketCallback? callback) {
    platformDispatcher.onPointerDataPacket = callback;
  }

  KeyDataCallback? get onKeyData => platformDispatcher.onKeyData;
  set onKeyData(KeyDataCallback? callback) {
    platformDispatcher.onKeyData = callback;
  }

  String get defaultRouteName => platformDispatcher.defaultRouteName;

  void scheduleFrame() => platformDispatcher.scheduleFrame();

  @override
  void render(Scene scene) => platformDispatcher.render(scene, this);

  bool get semanticsEnabled => platformDispatcher.semanticsEnabled;

  VoidCallback? get onSemanticsEnabledChanged => platformDispatcher.onSemanticsEnabledChanged;
  set onSemanticsEnabledChanged(VoidCallback? callback) {
    platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  SemanticsActionCallback? get onSemanticsAction => platformDispatcher.onSemanticsAction;
  set onSemanticsAction(SemanticsActionCallback? callback) {
    platformDispatcher.onSemanticsAction = callback;
  }

  FrameData get frameData => const FrameData._();

  VoidCallback? get onFrameDataChanged => null;
  set onFrameDataChanged(VoidCallback? callback) {}

  AccessibilityFeatures get accessibilityFeatures => platformDispatcher.accessibilityFeatures;

  VoidCallback? get onAccessibilityFeaturesChanged =>
      platformDispatcher.onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  void sendPlatformMessage(
    String name,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) {
    platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  PlatformMessageCallback? get onPlatformMessage => platformDispatcher.onPlatformMessage;
  set onPlatformMessage(PlatformMessageCallback? callback) {
    platformDispatcher.onPlatformMessage = callback;
  }

  void setIsolateDebugName(String name) => PlatformDispatcher.instance.setIsolateDebugName(name);
}

abstract class AccessibilityFeatures {
  bool get accessibleNavigation;
  bool get invertColors;
  bool get disableAnimations;
  bool get boldText;
  bool get reduceMotion;
  bool get highContrast;
  bool get onOffSwitchLabels;
}

enum Brightness {
  dark,
  light,
}

// Unimplemented classes.
// TODO(dit): see https://github.com/flutter/flutter/issues/33614.
class CallbackHandle {
  CallbackHandle.fromRawHandle(this._handle);

  final int _handle;

  int toRawHandle() => _handle;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;
}

// TODO(dit): see https://github.com/flutter/flutter/issues/33615.
class PluginUtilities {
  // This class is only a namespace, and should not be instantiated or
  // extended directly.
  factory PluginUtilities._() => throw UnsupportedError('Namespace');

  static CallbackHandle? getCallbackHandle(Function callback) {
    throw UnimplementedError();
  }

  static Function? getCallbackFromHandle(CallbackHandle handle) {
    throw UnimplementedError();
  }
}

class IsolateNameServer {
  // This class is only a namespace, and should not be instantiated or
  // extended directly.
  factory IsolateNameServer._() => throw UnsupportedError('Namespace');

  static dynamic lookupPortByName(String name) {
    throw UnimplementedError();
  }

  static bool registerPortWithName(dynamic port, String name) {
    throw UnimplementedError();
  }

  static bool removePortNameMapping(String name) {
    throw UnimplementedError();
  }
}

SingletonFlutterWindow get window => engine.window;

class FrameData {
  const FrameData._();

  const FrameData.webOnly();

  int get frameNumber => -1;
}

class GestureSettings {
  const GestureSettings({
    this.physicalTouchSlop,
    this.physicalDoubleTapSlop,
  });

  final double? physicalTouchSlop;

  final double? physicalDoubleTapSlop;

  GestureSettings copyWith({
    double? physicalTouchSlop,
    double? physicalDoubleTapSlop,
  }) {
    return GestureSettings(
      physicalTouchSlop: physicalTouchSlop ?? this.physicalTouchSlop,
      physicalDoubleTapSlop: physicalDoubleTapSlop ?? this.physicalDoubleTapSlop,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GestureSettings &&
      other.physicalTouchSlop == physicalTouchSlop &&
      other.physicalDoubleTapSlop == physicalDoubleTapSlop;
  }

  @override
  int get hashCode => Object.hash(physicalTouchSlop, physicalDoubleTapSlop);

  @override
  String toString() => 'GestureSettings(physicalTouchSlop: $physicalTouchSlop, physicalDoubleTapSlop: $physicalDoubleTapSlop)';
}
