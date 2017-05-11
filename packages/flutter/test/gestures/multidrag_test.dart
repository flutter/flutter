// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

class TestDrag extends Drag {
}

void main() {
  setUp(ensureGestureBinding);

  testGesture('MultiDrag control test', (GestureTester tester) {
    final DelayedMultiDragGestureRecognizer drag = new DelayedMultiDragGestureRecognizer();

    bool didStartDrag = false;
    drag.onStart = (Offset position) {
      didStartDrag = true;
      return new TestDrag();
    };

    final TestPointer pointer = new TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    tester.async.flushMicrotasks();
    expect(didStartDrag, isFalse);
    tester.route(pointer.move(const Offset(20.0, 20.0)));
    expect(didStartDrag, isFalse);
    tester.async.elapse(kLongPressTimeout * 2);
    expect(didStartDrag, isFalse);
    tester.route(pointer.move(const Offset(30.0, 30.0)));
    expect(didStartDrag, isFalse);
    drag.dispose();
  });
}
