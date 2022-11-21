// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeviceGestureSettings has reasonable hashCode', () {
    final DeviceGestureSettings settingsA = DeviceGestureSettings(touchSlop: nonconst(16));
    final DeviceGestureSettings settingsB = DeviceGestureSettings(touchSlop: nonconst(8));
    final DeviceGestureSettings settingsC = DeviceGestureSettings(touchSlop: nonconst(16));

    expect(settingsA.hashCode, settingsC.hashCode);
    expect(settingsA.hashCode, isNot(settingsB.hashCode));
  });

  test('DeviceGestureSettings has reasonable equality', () {
    final DeviceGestureSettings settingsA = DeviceGestureSettings(touchSlop: nonconst(16));
    final DeviceGestureSettings settingsB = DeviceGestureSettings(touchSlop: nonconst(8));
    final DeviceGestureSettings settingsC = DeviceGestureSettings(touchSlop: nonconst(16));

    expect(settingsA, equals(settingsC));
    expect(settingsA, isNot(settingsB));
  });
}
