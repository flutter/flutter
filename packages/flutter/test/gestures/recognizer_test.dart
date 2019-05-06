// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

class TestGestureRecognizer extends GestureRecognizer {
  TestGestureRecognizer({ Object debugOwner }) : super(debugOwner: debugOwner);

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

  test('CombinedOffset', () {
    const CombinedOffset offset = CombinedOffset(
      local: Offset(10, 20),
      global: Offset(30, 40),
    );

    expect(offset.local, const Offset(10, 20));
    expect(offset.global, const Offset(30, 40));

    final CombinedOffset sum = const CombinedOffset(
      local: Offset(50, 60),
      global: Offset(70, 80),
    ) + offset;

    expect(sum.local, const Offset(60, 80));
    expect(sum.global, const Offset(100, 120));
  });
}
