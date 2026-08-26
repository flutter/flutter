// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/gestures/distance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offsetExceedsThreshold matches Offset.distance comparisons', () {
    const offset = Offset(3.0, 4.0); // distance == 5.0

    expect(offsetExceedsThreshold(offset, 4.9), isTrue);
    expect(offsetExceedsThreshold(offset, 5.0), isFalse);
    expect(offsetExceedsThreshold(offset, 5.1), isFalse);
    expect(offsetExceedsThreshold(Offset.zero, 0.0), isFalse);
    expect(() => offsetExceedsThreshold(offset, -1.0), throwsAssertionError);
  });
}
