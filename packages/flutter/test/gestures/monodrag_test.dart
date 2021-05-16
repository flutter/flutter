// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('do not crash on up event for a pending pointer after winning arena for another pointer', (GestureTester tester) {
    // Regression test for https://github.com/flutter/flutter/issues/75061.

    final VerticalDragGestureRecognizer v = VerticalDragGestureRecognizer()
      ..onStart = (_) { };
    final HorizontalDragGestureRecognizer h = HorizontalDragGestureRecognizer()
      ..onStart = (_) { };

    const PointerDownEvent down90 = PointerDownEvent(
      pointer: 90,
      position: Offset(10.0, 10.0),
    );

    const PointerUpEvent up90 = PointerUpEvent(
      pointer: 90,
      position: Offset(10.0, 10.0),
    );

    const PointerDownEvent down91 = PointerDownEvent(
      pointer: 91,
      position: Offset(20.0, 20.0),
    );

    const PointerUpEvent up91 = PointerUpEvent(
      pointer: 91,
      position: Offset(20.0, 20.0),
    );

    v.addPointer(down90);
    GestureBinding.instance!.gestureArena.close(90);
    h.addPointer(down91);
    v.addPointer(down91);
    GestureBinding.instance!.gestureArena.close(91);
    tester.async.flushMicrotasks();

    GestureBinding.instance!.handleEvent(up90, HitTestEntry(MockHitTestTarget()));
    GestureBinding.instance!.handleEvent(up91, HitTestEntry(MockHitTestTarget()));
  });
}

class MockHitTestTarget implements HitTestTarget {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) { }
}
