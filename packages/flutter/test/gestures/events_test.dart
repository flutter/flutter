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
