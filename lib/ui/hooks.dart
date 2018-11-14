// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

String _decodeUTF8(ByteData message) {
  return message != null ? utf8.decoder.convert(message.buffer.asUint8List()) : null;
}

dynamic _decodeJSON(String message) {
  return message != null ? json.decode(message) : null;
}

@pragma('vm:entry-point')
void _updateWindowMetrics(double devicePixelRatio,
                          double width,
                          double height,
                          double paddingTop,
                          double paddingRight,
                          double paddingBottom,
                          double paddingLeft,
                          double viewInsetTop,
                          double viewInsetRight,
                          double viewInsetBottom,
                          double viewInsetLeft) {
  window
    .._devicePixelRatio = devicePixelRatio
    .._physicalSize = new Size(width, height)
    .._padding = new WindowPadding._(
        top: paddingTop,
        right: paddingRight,
        bottom: paddingBottom,
        left: paddingLeft)
    .._viewInsets = new WindowPadding._(
        top: viewInsetTop,
        right: viewInsetRight,
        bottom: viewInsetBottom,
        left: viewInsetLeft);
  _invoke(window.onMetricsChanged, window._onMetricsChangedZone);
}

typedef _LocaleClosure = String Function();

String _localeClosure() => window.locale.toString();

@pragma('vm:entry-point')
_LocaleClosure _getLocaleClosure() => _localeClosure;

@pragma('vm:entry-point')
void _updateLocales(List<String> locales) {
  const int stringsPerLocale = 4;
  final int numLocales = locales.length ~/ stringsPerLocale;
  window._locales = new List<Locale>(numLocales);
  for (int localeIndex = 0; localeIndex < numLocales; localeIndex++) {
    final String countryCode = locales[localeIndex * stringsPerLocale + 1];
    final String scriptCode = locales[localeIndex * stringsPerLocale + 2];

    window._locales[localeIndex] = new Locale.fromSubtags(
      languageCode: locales[localeIndex * stringsPerLocale],
      countryCode: countryCode.isEmpty ? null : countryCode,
      scriptCode: scriptCode.isEmpty ? null : scriptCode,
    );
  }
  _invoke(window.onLocaleChanged, window._onLocaleChangedZone);
}

@pragma('vm:entry-point')
void _updateUserSettingsData(String jsonData) {
  final Map<String, dynamic> data = json.decode(jsonData);
  if (data.isEmpty) {
    return;
  }
  _updateTextScaleFactor(data['textScaleFactor'].toDouble());
  _updateAlwaysUse24HourFormat(data['alwaysUse24HourFormat']);
}

void _updateTextScaleFactor(double textScaleFactor) {
  window._textScaleFactor = textScaleFactor;
  _invoke(window.onTextScaleFactorChanged, window._onTextScaleFactorChangedZone);
}

void _updateAlwaysUse24HourFormat(bool alwaysUse24HourFormat) {
  window._alwaysUse24HourFormat = alwaysUse24HourFormat;
}

@pragma('vm:entry-point')
void _updateSemanticsEnabled(bool enabled) {
  window._semanticsEnabled = enabled;
  _invoke(window.onSemanticsEnabledChanged, window._onSemanticsEnabledChangedZone);
}

@pragma('vm:entry-point')
void _updateAccessibilityFeatures(int values) {
  final AccessibilityFeatures newFeatures = new AccessibilityFeatures._(values);
  if (newFeatures == window._accessibilityFeatures)
    return;
  window._accessibilityFeatures = newFeatures;
  _invoke(window.onAccessibilityFeaturesChanged, window._onAccessibilityFlagsChangedZone);
}

@pragma('vm:entry-point')
void _dispatchPlatformMessage(String name, ByteData data, int responseId) {
  if (window.onPlatformMessage != null) {
    _invoke3<String, ByteData, PlatformMessageResponseCallback>(
      window.onPlatformMessage,
      window._onPlatformMessageZone,
      name,
      data,
      (ByteData responseData) {
        window._respondToPlatformMessage(responseId, responseData);
      },
    );
  } else {
    window._respondToPlatformMessage(responseId, null);
  }
}

@pragma('vm:entry-point')
void _dispatchPointerDataPacket(ByteData packet) {
  if (window.onPointerDataPacket != null)
    _invoke1<PointerDataPacket>(window.onPointerDataPacket, window._onPointerDataPacketZone, _unpackPointerDataPacket(packet));
}

@pragma('vm:entry-point')
void _dispatchSemanticsAction(int id, int action, ByteData args) {
  _invoke3<int, SemanticsAction, ByteData>(
    window.onSemanticsAction,
    window._onSemanticsActionZone,
    id,
    SemanticsAction.values[action],
    args,
  );
}

@pragma('vm:entry-point')
void _beginFrame(int microseconds) {
  _invoke1<Duration>(window.onBeginFrame, window._onBeginFrameZone, new Duration(microseconds: microseconds));
}

@pragma('vm:entry-point')
void _drawFrame() {
  _invoke(window.onDrawFrame, window._onDrawFrameZone);
}

/// Invokes [callback] inside the given [zone].
void _invoke(void callback(), Zone zone) {
  if (callback == null)
    return;

  assert(zone != null);

  if (identical(zone, Zone.current)) {
    callback();
  } else {
    zone.runGuarded(callback);
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg].
void _invoke1<A>(void callback(A a), Zone zone, A arg) {
  if (callback == null)
    return;

  assert(zone != null);

  if (identical(zone, Zone.current)) {
    callback(arg);
  } else {
    zone.runUnaryGuarded<A>(callback, arg);
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg1] and [arg2].
void _invoke2<A1, A2>(void callback(A1 a1, A2 a2), Zone zone, A1 arg1, A2 arg2) {
  if (callback == null)
    return;

  assert(zone != null);

  if (identical(zone, Zone.current)) {
    callback(arg1, arg2);
  } else {
    zone.runBinaryGuarded<A1, A2>(callback, arg1, arg2);
  }
}

/// Invokes [callback] inside the given [zone] passing it [arg1], [arg2] and [arg3].
void _invoke3<A1, A2, A3>(void callback(A1 a1, A2 a2, A3 a3), Zone zone, A1 arg1, A2 arg2, A3 arg3) {
  if (callback == null)
    return;

  assert(zone != null);

  if (identical(zone, Zone.current)) {
    callback(arg1, arg2, arg3);
  } else {
    zone.runGuarded(() {
      callback(arg1, arg2, arg3);
    });
  }
}

// If this value changes, update the encoding code in the following files:
//
//  * pointer_data.cc
//  * FlutterView.java
const int _kPointerDataFieldCount = 21;

PointerDataPacket _unpackPointerDataPacket(ByteData packet) {
  const int kStride = Int64List.bytesPerElement;
  const int kBytesPerPointerData = _kPointerDataFieldCount * kStride;
  final int length = packet.lengthInBytes ~/ kBytesPerPointerData;
  assert(length * kBytesPerPointerData == packet.lengthInBytes);
  final List<PointerData> data = new List<PointerData>(length);
  for (int i = 0; i < length; ++i) {
    int offset = i * _kPointerDataFieldCount;
    data[i] = new PointerData(
      timeStamp: new Duration(microseconds: packet.getInt64(kStride * offset++, _kFakeHostEndian)),
      change: PointerChange.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
      kind: PointerDeviceKind.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
      device: packet.getInt64(kStride * offset++, _kFakeHostEndian),
      physicalX: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      physicalY: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      buttons: packet.getInt64(kStride * offset++, _kFakeHostEndian),
      obscured: packet.getInt64(kStride * offset++, _kFakeHostEndian) != 0,
      pressure: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      pressureMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      pressureMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      distance: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      distanceMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      size: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMajor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMinor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      orientation: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      tilt: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      platformData: packet.getInt64(kStride * offset++, _kFakeHostEndian),
    );
    assert(offset == (i + 1) * _kPointerDataFieldCount);
  }
  return new PointerDataPacket(data: data);
}
