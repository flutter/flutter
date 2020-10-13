// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

class TestGestureRecognizer extends GestureRecognizer {
  TestGestureRecognizer({ Object? debugOwner }) : super(debugOwner: debugOwner);

  @override
  String get debugDescription => 'debugDescription content';

  @override
  void addPointer(PointerDownEvent event) { }

  @override
  void acceptGesture(int pointer) { }

  @override
  void rejectGesture(int pointer) { }
}

void main() {
  test('GestureRecognizer smoketest', () {
    final TestGestureRecognizer recognizer = TestGestureRecognizer(debugOwner: 0);
    expect(recognizer, hasAGoodToStringDeep);
  });

  test('OffsetPair', () {
    const OffsetPair offset1 = OffsetPair(
      local: Offset(10, 20),
      global: Offset(30, 40),
    );

    expect(offset1.local, const Offset(10, 20));
    expect(offset1.global, const Offset(30, 40));

    const OffsetPair offset2 = OffsetPair(
      local: Offset(50, 60),
      global: Offset(70, 80),
    );

    final OffsetPair sum = offset2 + offset1;
    expect(sum.local, const Offset(60, 80));
    expect(sum.global, const Offset(100, 120));

    final OffsetPair difference = offset2 - offset1;
    expect(difference.local, const Offset(40, 40));
    expect(difference.global, const Offset(40, 40));

  });
}
