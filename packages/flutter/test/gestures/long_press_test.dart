// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';
import 'gesture_tester.dart';

const PointerDownEvent down = PointerDownEvent(
  pointer: 5,
  position: Offset(10, 10),
);

const PointerUpEvent up = PointerUpEvent(
  pointer: 5,
  position: Offset(11, 9),
);

const PointerMoveEvent move = PointerMoveEvent(
  pointer: 5,
  position: Offset(100, 200),
);

void main() {
  setUp(ensureGestureBinding);

  group('Long press', () {
    LongPressGestureRecognizer longPress;
    bool longPressDown;
    bool longPressUp;

    setUp(() {
      longPress = LongPressGestureRecognizer();
      longPressDown = false;
      longPress.onLongPress = () {
        longPressDown = true;
      };
      longPressUp = false;
      longPress.onLongPressUp = () {
        longPressUp = true;
      };
    });

    testGesture('Should recognize long press', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(longPressDown, isTrue);

      longPress.dispose();
    });

    testGesture('Up cancels long press', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isFalse);
      tester.route(up);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      expect(longPressDown, isFalse);

      longPress.dispose();
    });

    testGesture('Moving before accept cancels', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isFalse);
      tester.route(move);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      tester.route(up);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isFalse);
      expect(longPressUp, isFalse);

      longPress.dispose();
    });

    testGesture('Moving after accept is ok', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      expect(longPressDown, isTrue);
      tester.route(move);
      tester.route(up);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isTrue);
      expect(longPressUp, isTrue);

      longPress.dispose();
    });

    testGesture('Should recognize both tap down and long press', (GestureTester tester) {
      final TapGestureRecognizer tap = TapGestureRecognizer();

      bool tapDownRecognized = false;
      tap.onTapDown = (_) {
        tapDownRecognized = true;
      };

      tap.addPointer(down);
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(tapDownRecognized, isFalse);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(tapDownRecognized, isFalse);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(tapDownRecognized, isTrue);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(tapDownRecognized, isTrue);
      expect(longPressDown, isTrue);

      tap.dispose();
      longPress.dispose();
    });

    testGesture('Drag start delayed by microtask', (GestureTester tester) {
      final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();

      bool isDangerousStack = false;

      bool dragStartRecognized = false;
      drag.onStart = (DragStartDetails details) {
        expect(isDangerousStack, isFalse);
        dragStartRecognized = true;
      };

      drag.addPointer(down);
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(dragStartRecognized, isFalse);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(dragStartRecognized, isFalse);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(dragStartRecognized, isFalse);
      expect(longPressDown, isFalse);
      isDangerousStack = true;
      longPress.dispose();
      isDangerousStack = false;
      expect(dragStartRecognized, isFalse);
      expect(longPressDown, isFalse);
      tester.async.flushMicrotasks();
      expect(dragStartRecognized, isTrue);
      expect(longPressDown, isFalse);
      drag.dispose();
    });

    testGesture('Should recognize long press up', (GestureTester tester) {
      bool longPressUpRecognized = false;
      longPress.onLongPressUp = () {
        longPressUpRecognized = true;
      };

      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressUpRecognized, isFalse);
      tester.route(down); // kLongPressTimeout = 500;
      expect(longPressUpRecognized, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressUpRecognized, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up);
      expect(longPressUpRecognized, isTrue);

      longPress.dispose();
    });
  });

  group('long press drag', () {
    LongPressGestureRecognizer longPressDrag;
    bool longPressStart;
    bool longPressUp;
    Offset longPressDragUpdate;

    setUp(() {
      longPressDrag = LongPressGestureRecognizer();
      longPressStart = false;
      longPressDrag.onLongPressStart = (LongPressStartDetails details) {
        longPressStart = true;
      };
      longPressUp = false;
      longPressDrag.onLongPressEnd = (LongPressEndDetails details) {
        longPressUp = true;
      };
      longPressDragUpdate = null;
      longPressDrag.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
        longPressDragUpdate = details.globalPosition;
      };
    });

    testGesture('Should recognize long press down', (GestureTester tester) {
      longPressDrag.addPointer(down);
      tester.closeArena(5);
      expect(longPressStart, isFalse);
      tester.route(down);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(longPressStart, isTrue);

      longPressDrag.dispose();
    });

    testGesture('Short up cancels long press', (GestureTester tester) {
      longPressDrag.addPointer(down);
      tester.closeArena(5);
      expect(longPressStart, isFalse);
      tester.route(down);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressStart, isFalse);
      tester.route(up);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      expect(longPressStart, isFalse);

      longPressDrag.dispose();
    });

    testGesture('Moving before accept cancels', (GestureTester tester) {
      longPressDrag.addPointer(down);
      tester.closeArena(5);
      expect(longPressStart, isFalse);
      tester.route(down);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressStart, isFalse);
      tester.route(move);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      tester.route(up);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressStart, isFalse);
      expect(longPressUp, isFalse);

      longPressDrag.dispose();
    });

    testGesture('Moving after accept does not cancel', (GestureTester tester) {
      longPressDrag.addPointer(down);
      tester.closeArena(5);
      expect(longPressStart, isFalse);
      tester.route(down);
      expect(longPressStart, isFalse);
      tester.async.elapse(const Duration(seconds: 1));
      expect(longPressStart, isTrue);
      tester.route(move);
      expect(longPressDragUpdate, const Offset(100, 200));
      tester.route(up);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressStart, isTrue);
      expect(longPressUp, isTrue);

      longPressDrag.dispose();
    });
  });

  testGesture('Can filter long press based on device kind', (GestureTester tester) {
    final LongPressGestureRecognizer mouseLongPress = LongPressGestureRecognizer(kind: PointerDeviceKind.mouse);

    bool mouseLongPressDown = false;
    mouseLongPress.onLongPress = () {
      mouseLongPressDown = true;
    };

    const PointerDownEvent mouseDown = PointerDownEvent(
      pointer: 5,
      position: Offset(10, 10),
      kind: PointerDeviceKind.mouse,
    );
    const PointerDownEvent touchDown = PointerDownEvent(
      pointer: 5,
      position: Offset(10, 10),
      kind: PointerDeviceKind.touch,
    );

    // Touch events shouldn't be recognized.
    mouseLongPress.addPointer(touchDown);
    tester.closeArena(5);
    expect(mouseLongPressDown, isFalse);
    tester.route(touchDown);
    expect(mouseLongPressDown, isFalse);
    tester.async.elapse(const Duration(seconds: 2));
    expect(mouseLongPressDown, isFalse);

    // Mouse events are still recognized.
    mouseLongPress.addPointer(mouseDown);
    tester.closeArena(5);
    expect(mouseLongPressDown, isFalse);
    tester.route(mouseDown);
    expect(mouseLongPressDown, isFalse);
    tester.async.elapse(const Duration(seconds: 2));
    expect(mouseLongPressDown, isTrue);

    mouseLongPress.dispose();
  });
}
