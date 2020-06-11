// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

class TestDrag extends Drag { }

void main() {
  setUp(ensureGestureBinding);

  testGesture('MultiDrag: moving before delay rejects', (GestureTester tester) {
    final DelayedMultiDragGestureRecognizer drag = DelayedMultiDragGestureRecognizer();

    bool didStartDrag = false;
    drag.onStart = (Offset position) {
      didStartDrag = true;
      return TestDrag();
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    tester.async.flushMicrotasks();
    expect(didStartDrag, isFalse);
    tester.route(pointer.move(const Offset(20.0, 60.0))); // move more than touch slop before delay expires
    expect(didStartDrag, isFalse);
    tester.async.elapse(kLongPressTimeout * 2); // expire delay
    expect(didStartDrag, isFalse);
    tester.route(pointer.move(const Offset(30.0, 120.0))); // move some more after delay expires
    expect(didStartDrag, isFalse);
    drag.dispose();
  });

  testGesture('MultiDrag: delay triggers', (GestureTester tester) {
    final DelayedMultiDragGestureRecognizer drag = DelayedMultiDragGestureRecognizer();

    bool didStartDrag = false;
    drag.onStart = (Offset position) {
      didStartDrag = true;
      return TestDrag();
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    tester.async.flushMicrotasks();
    expect(didStartDrag, isFalse);
    tester.route(pointer.move(const Offset(20.0, 20.0))); // move less than touch slop before delay expires
    expect(didStartDrag, isFalse);
    tester.async.elapse(kLongPressTimeout * 2); // expire delay
    expect(didStartDrag, isTrue);
    tester.route(pointer.move(const Offset(30.0, 70.0))); // move more than touch slop after delay expires
    expect(didStartDrag, isTrue);
    drag.dispose();
  });

  testGesture('MultiDrag: can filter based on device kind', (GestureTester tester) {
    final DelayedMultiDragGestureRecognizer drag =
        DelayedMultiDragGestureRecognizer(kind: PointerDeviceKind.touch);

    bool didStartDrag = false;
    drag.onStart = (Offset position) {
      didStartDrag = true;
      return TestDrag();
    };

    final TestPointer mousePointer = TestPointer(5, PointerDeviceKind.mouse);
    final PointerDownEvent down = mousePointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    tester.async.flushMicrotasks();
    expect(didStartDrag, isFalse);
    tester.route(mousePointer.move(const Offset(20.0, 20.0))); // move less than touch slop before delay expires
    expect(didStartDrag, isFalse);
    tester.async.elapse(kLongPressTimeout * 2); // expire delay
    // Still false because it shouldn't recognize mouse events.
    expect(didStartDrag, isFalse);
    tester.route(mousePointer.move(const Offset(30.0, 70.0))); // move more than touch slop after delay expires
    // And still false.
    expect(didStartDrag, isFalse);
    drag.dispose();
  });
}
