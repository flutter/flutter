// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of ui;

abstract class FlutterView {
  PlatformDispatcher get platformDispatcher;
  ViewConfiguration get viewConfiguration;
  double get devicePixelRatio => viewConfiguration.devicePixelRatio;
  Rect get physicalGeometry => viewConfiguration.geometry;
  Size get physicalSize => viewConfiguration.geometry.size;
  WindowPadding get viewInsets => viewConfiguration.viewInsets;
  WindowPadding get viewPadding => viewConfiguration.viewPadding;
  WindowPadding get systemGestureInsets => viewConfiguration.systemGestureInsets;
  WindowPadding get padding => viewConfiguration.padding;
  void render(Scene scene) => platformDispatcher.render(scene, this);
}

abstract class FlutterWindow extends FlutterView {
  @override
  PlatformDispatcher get platformDispatcher;

  @override
  ViewConfiguration get viewConfiguration;
}

abstract class SingletonFlutterWindow extends FlutterWindow {
  VoidCallback? get onMetricsChanged => platformDispatcher.onMetricsChanged;
  set onMetricsChanged(VoidCallback? callback) {
    platformDispatcher.onMetricsChanged = callback;
  }

  Locale? get locale => platformDispatcher.locale;
  List<Locale>? get locales => platformDispatcher.locales;

  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    return platformDispatcher.computePlatformResolvedLocale(supportedLocales);
  }

  VoidCallback? get onLocaleChanged => platformDispatcher.onLocaleChanged;
  set onLocaleChanged(VoidCallback? callback) {
    platformDispatcher.onLocaleChanged = callback;
  }

  String get initialLifecycleState => platformDispatcher.initialLifecycleState;

  double get textScaleFactor => platformDispatcher.textScaleFactor;
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

  String get defaultRouteName => platformDispatcher.defaultRouteName;

  void scheduleFrame() => platformDispatcher.scheduleFrame();
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

  AccessibilityFeatures get accessibilityFeatures => platformDispatcher.accessibilityFeatures;

  VoidCallback? get onAccessibilityFeaturesChanged =>
      platformDispatcher.onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  void updateSemantics(SemanticsUpdate update) => platformDispatcher.updateSemantics(update);

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

class AccessibilityFeatures {
  const AccessibilityFeatures._(this._index);

  static const int _kAccessibleNavigation = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;
  static const int _kHighContrastIndex = 1 << 5;

  // A bitfield which represents each enabled feature.
  final int _index;

  bool get accessibleNavigation => _kAccessibleNavigation & _index != 0;
  bool get invertColors => _kInvertColorsIndex & _index != 0;
  bool get disableAnimations => _kDisableAnimationsIndex & _index != 0;
  bool get boldText => _kBoldTextIndex & _index != 0;
  bool get reduceMotion => _kReduceMotionIndex & _index != 0;
  bool get highContrast => _kHighContrastIndex & _index != 0;

  @override
  String toString() {
    final List<String> features = <String>[];
    if (accessibleNavigation) {
      features.add('accessibleNavigation');
    }
    if (invertColors) {
      features.add('invertColors');
    }
    if (disableAnimations) {
      features.add('disableAnimations');
    }
    if (boldText) {
      features.add('boldText');
    }
    if (reduceMotion) {
      features.add('reduceMotion');
    }
    if (highContrast) {
      features.add('highContrast');
    }
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AccessibilityFeatures
        && other._index == _index;
  }

  @override
  int get hashCode => _index.hashCode;
}

enum Brightness {
  dark,
  light,
}

// Unimplemented classes.
// TODO(flutter_web): see https://github.com/flutter/flutter/issues/33614.
class CallbackHandle {
  CallbackHandle.fromRawHandle(this._handle)
    : assert(_handle != null, "'_handle' must not be null."); // ignore: unnecessary_null_comparison

  final int _handle;

  int toRawHandle() => _handle;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => super.hashCode;
}

// TODO(flutter_web): see https://github.com/flutter/flutter/issues/33615.
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
