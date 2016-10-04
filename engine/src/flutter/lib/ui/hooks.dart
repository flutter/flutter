// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

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

void _pushRoute(String route) {
  assert(window._defaultRouteName == null);
  window._defaultRouteName = route;
  // TODO(abarth): If we ever start calling _pushRoute other than before main,
  // we should add a change notification callback.
}

void _popRoute() {
  if (window.onPopRoute != null)
    window.onPopRoute();
}

void _dispatchPointerDataPacket(ByteData packet) {
  if (window.onPointerDataPacket != null)
    window.onPointerDataPacket(_unpackPointerDataPacket(packet));
}

void _beginFrame(int microseconds) {
  if (window.onBeginFrame != null)
    window.onBeginFrame(new Duration(microseconds: microseconds));
}

void _onAppLifecycleStateChanged(int state) {
  if (window.onAppLifecycleStateChanged != null)
    window.onAppLifecycleStateChanged(AppLifecycleState.values[state]);
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
