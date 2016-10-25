// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

String _decodeUTF8(ByteData message) {
  return message != null ? UTF8.decoder.convert(message.buffer.asUint8List()) : null;
}

dynamic _decodeJSON(String message) {
  return message != null ? JSON.decode(message) : null;
}

void _updateWindowMetrics(double devicePixelRatio,
                          double width,
                          double height,
                          double top,
                          double right,
                          double bottom,
                          double left) {
  window
    .._devicePixelRatio = devicePixelRatio
    .._physicalSize = new Size(width, height)
    .._padding = new WindowPadding._(
      top: top, right: right, bottom: bottom, left: left);
  if (window.onMetricsChanged != null)
    window.onMetricsChanged();
}

void _updateLocale(String languageCode, String countryCode) {
  window._locale = new Locale(languageCode, countryCode);
  if (window.onLocaleChanged != null)
    window.onLocaleChanged();
}

void _updateSemanticsEnabled(bool enabled) {
  window._semanticsEnabled = enabled;
  if (window.onSemanticsEnabledChanged != null)
    window.onSemanticsEnabledChanged();
}

void _handleNavigationMessage(ByteData data) {
  if (window._defaultRouteName != null)
    return;
  try {
    final dynamic message = _decodeJSON(_decodeUTF8(data));
    final dynamic method = message['method'];
    if (method != 'pushRoute')
      return;
    final dynamic args = message['args'];
    window._defaultRouteName = args[0];
  } catch (e) {
    // We ignore any exception and just let the message be dispatched as usual.
  }
}

void _dispatchPlatformMessage(String name, ByteData data, int responseId) {
  if (name == 'flutter/navigation')
    _handleNavigationMessage(data);

  if (window.onPlatformMessage != null) {
    window.onPlatformMessage(name, data, (ByteData responseData) {
      window._respondToPlatformMessage(responseId, responseData);
    });
  } else {
    window._respondToPlatformMessage(responseId, null);
  }
}

void _dispatchPointerDataPacket(ByteData packet) {
  if (window.onPointerDataPacket != null)
    window.onPointerDataPacket(_unpackPointerDataPacket(packet));
}

void _dispatchSemanticsAction(int id, int action) {
  if (window.onSemanticsAction != null)
    window.onSemanticsAction(id, SemanticsAction.values[action]);
}

void _beginFrame(int microseconds) {
  if (window.onBeginFrame != null)
    window.onBeginFrame(new Duration(microseconds: microseconds));
}

// If this value changes, update the encoding code in the following files:
//
//  * pointer_data.cc
//  * FlutterView.java
const int _kPointerDataFieldCount = 19;

PointerDataPacket _unpackPointerDataPacket(ByteData packet) {
  const int kStride = Int64List.BYTES_PER_ELEMENT;
  const int kBytesPerPointerData = _kPointerDataFieldCount * kStride;
  final int length = packet.lengthInBytes ~/ kBytesPerPointerData;
  assert(length * kBytesPerPointerData == packet.lengthInBytes);
  List<PointerData> pointers = new List<PointerData>(length);
  for (int i = 0; i < length; ++i) {
    int offset = i * _kPointerDataFieldCount;
    pointers[i] = new PointerData(
      timeStamp: new Duration(microseconds: packet.getInt64(kStride * offset++, _kFakeHostEndian)),
      pointer: packet.getInt64(kStride * offset++, _kFakeHostEndian),
      change: PointerChange.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
      kind: PointerDeviceKind.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
      physicalX: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      physicalY: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      buttons: packet.getInt64(kStride * offset++, _kFakeHostEndian),
      obscured: packet.getInt64(kStride * offset++, _kFakeHostEndian) != 0,
      pressure: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      pressureMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      pressureMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      distance: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      distanceMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMajor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMinor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      radiusMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      orientation: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      tilt: packet.getFloat64(kStride * offset++, _kFakeHostEndian)
    );
    assert(offset == (i + 1) * _kPointerDataFieldCount);
  }
  return new PointerDataPacket(pointers: pointers);
}
