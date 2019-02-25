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
}
