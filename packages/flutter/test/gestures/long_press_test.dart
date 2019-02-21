// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';
import 'gesture_tester.dart';

const PointerDownEvent down = PointerDownEvent(
  pointer: 5,
  position: Offset(10.0, 10.0)
);

const PointerUpEvent up = PointerUpEvent(
  pointer: 5,
  position: Offset(11.0, 9.0)
);

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize long press', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer();

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    longPress.addPointer(down);
    tester.closeArena(5);
    expect(longPressRecognized, isFalse);
    tester.route(down);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 300));
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 700));
    expect(longPressRecognized, isTrue);

    longPress.dispose();
  });

  testGesture('Up cancels long press', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer();

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    longPress.addPointer(down);
    tester.closeArena(5);
    expect(longPressRecognized, isFalse);
    tester.route(down);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 300));
    expect(longPressRecognized, isFalse);
    tester.route(up);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(seconds: 1));
    expect(longPressRecognized, isFalse);

    longPress.dispose();
  });

  testGesture('Should recognize both tap down and long press', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer();
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapDownRecognized = false;
    tap.onTapDown = (_) {
      tapDownRecognized = true;
    };

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    tap.addPointer(down);
    longPress.addPointer(down);
    tester.closeArena(5);
    expect(tapDownRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    tester.route(down);
    expect(tapDownRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 300));
    expect(tapDownRecognized, isTrue);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 700));
    expect(tapDownRecognized, isTrue);
    expect(longPressRecognized, isTrue);

    tap.dispose();
    longPress.dispose();
  });

  testGesture('Drag start delayed by microtask', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();

    bool isDangerousStack = false;

    bool dragStartRecognized = false;
    drag.onStart = (DragStartDetails details) {
      expect(isDangerousStack, isFalse);
      dragStartRecognized = true;
    };

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      expect(isDangerousStack, isFalse);
      longPressRecognized = true;
    };

    drag.addPointer(down);
    longPress.addPointer(down);
    tester.closeArena(5);
    expect(dragStartRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    tester.route(down);
    expect(dragStartRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    tester.async.elapse(const Duration(milliseconds: 300));
    expect(dragStartRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    isDangerousStack = true;
    longPress.dispose();
    isDangerousStack = false;
    expect(dragStartRecognized, isFalse);
    expect(longPressRecognized, isFalse);
    tester.async.flushMicrotasks();
    expect(dragStartRecognized, isTrue);
    expect(longPressRecognized, isFalse);
    drag.dispose();
  });

  testGesture('Should recognize long press up', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer();

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
}
