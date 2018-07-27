// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

import 'gesture_tester.dart';

const PointerDownEvent down = const PointerDownEvent(
  pointer: 5,
  position: const Offset(10.0, 10.0)
);

const PointerUpEvent up = const PointerUpEvent(
  pointer: 5,
  position: const Offset(11.0, 9.0)
);

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize long press', (GestureTester tester) {
    final LongPressGestureRecognizer longPress = new LongPressGestureRecognizer();

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
    final LongPressGestureRecognizer longPress = new LongPressGestureRecognizer();

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
    final LongPressGestureRecognizer longPress = new LongPressGestureRecognizer();
    final TapGestureRecognizer tap = new TapGestureRecognizer();

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
    final LongPressGestureRecognizer longPress = new LongPressGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = new HorizontalDragGestureRecognizer();

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

}
