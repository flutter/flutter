// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('toString control tests', (GestureTester tester) {
    expect(const PointerDownEvent(), hasOneLineDescription);
    expect(const PointerDownEvent().toStringFull(), hasOneLineDescription);
  });

  testGesture('nthMouseButton control tests', (GestureTester tester) {
    expect(nthMouseButton(2), kSecondaryMouseButton);
    expect(nthStylusButton(2), kSecondaryStylusButton);
  });

  testGesture('smallestButton tests', (GestureTester tester) {
    expect(smallestButton(0x0), equals(0x0));
    expect(smallestButton(0x1), equals(0x1));
    expect(smallestButton(0x200), equals(0x200));
    expect(smallestButton(0x220), equals(0x20));
  });

  testGesture('isSingleButton tests', (GestureTester tester) {
    expect(isSingleButton(0x0), isFalse);
    expect(isSingleButton(0x1), isTrue);
    expect(isSingleButton(0x200), isTrue);
    expect(isSingleButton(0x220), isFalse);
  });

  group('fromMouseEvent', () {
    const PointerEvent hover = PointerHoverEvent(
      timeStamp: Duration(days: 1),
      kind: PointerDeviceKind.unknown,
      device: 10,
      position: Offset(101.0, 202.0),
      buttons: 7,
      obscured: true,
      pressureMax: 2.1,
      pressureMin: 1.1,
      distance: 11,
      distanceMax: 110,
      size: 11,
      radiusMajor: 11,
      radiusMinor: 9,
      radiusMin: 1.1,
      radiusMax: 22,
      orientation: 1.1,
      tilt: 1.1,
      synthesized: true,
    );

    test('PointerEnterEvent.fromMouseEvent', () {
      final PointerEnterEvent event = PointerEnterEvent.fromMouseEvent(hover);
      const PointerEnterEvent empty = PointerEnterEvent();
      expect(event.timeStamp,   hover.timeStamp);
      expect(event.pointer,     empty.pointer);
      expect(event.kind,        hover.kind);
      expect(event.device,      hover.device);
      expect(event.position,    hover.position);
      expect(event.buttons,     hover.buttons);
      expect(event.down,        empty.down);
      expect(event.obscured,    hover.obscured);
      expect(event.pressure,    empty.pressure);
      expect(event.pressureMin, hover.pressureMin);
      expect(event.pressureMax, hover.pressureMax);
      expect(event.distance,    hover.distance);
      expect(event.distanceMax, hover.distanceMax);
      expect(event.distanceMax, hover.distanceMax);
      expect(event.size,        hover.size);
      expect(event.radiusMajor, hover.radiusMajor);
      expect(event.radiusMinor, hover.radiusMinor);
      expect(event.radiusMin,   hover.radiusMin);
      expect(event.radiusMax,   hover.radiusMax);
      expect(event.orientation, hover.orientation);
      expect(event.tilt,        hover.tilt);
      expect(event.synthesized, hover.synthesized);
    });

    test('PointerExitEvent.fromMouseEvent', () {
      final PointerExitEvent event = PointerExitEvent.fromMouseEvent(hover);
      const PointerExitEvent empty = PointerExitEvent();
      expect(event.timeStamp,   hover.timeStamp);
      expect(event.pointer,     empty.pointer);
      expect(event.kind,        hover.kind);
      expect(event.device,      hover.device);
      expect(event.position,    hover.position);
      expect(event.buttons,     hover.buttons);
      expect(event.down,        empty.down);
      expect(event.obscured,    hover.obscured);
      expect(event.pressure,    empty.pressure);
      expect(event.pressureMin, hover.pressureMin);
      expect(event.pressureMax, hover.pressureMax);
      expect(event.distance,    hover.distance);
      expect(event.distanceMax, hover.distanceMax);
      expect(event.distanceMax, hover.distanceMax);
      expect(event.size,        hover.size);
      expect(event.radiusMajor, hover.radiusMajor);
      expect(event.radiusMinor, hover.radiusMinor);
      expect(event.radiusMin,   hover.radiusMin);
      expect(event.radiusMax,   hover.radiusMax);
      expect(event.orientation, hover.orientation);
      expect(event.tilt,        hover.tilt);
      expect(event.synthesized, hover.synthesized);
    });
  });

  group('Default values of PointerEvents:', () {
    // Some parameters are intentionally set to a non-trivial value.

    test('PointerDownEvent', () {
      const PointerDownEvent event = PointerDownEvent();
      expect(event.buttons, kPrimaryButton);
    });

    test('PointerMoveEvent', () {
      const PointerMoveEvent event = PointerMoveEvent();
      expect(event.buttons, kPrimaryButton);
    });
  });
}
