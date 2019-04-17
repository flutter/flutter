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

    testGesture('Should not recognize long press with more than one buttons', (GestureTester tester) {
      longPress.addPointer(const PointerDownEvent(
        pointer: 5,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton | kMiddleMouseButton,
        position: Offset(10, 10),
      ));
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(longPressDown, isFalse);
      tester.route(up);
      expect(longPressUp, isFalse);

      longPress.dispose();
    });

    testGesture('Should cancel long press when buttons change before acceptance', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(longPressDown, isFalse);
      tester.route(const PointerMoveEvent(
        pointer: 5,
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
        position: Offset(10, 10),
      ));
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(longPressDown, isFalse);
      tester.route(up);
      expect(longPressUp, isFalse);

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

  group('Enforce consistent-button restriction for onAnyLongPress:', () {
    // In sequence between `down` and `up` but with buttons changed
    const PointerMoveEvent moveM = PointerMoveEvent(
      pointer: 5,
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
      position: Offset(10, 10),
    );

    // Another valid down-up sequence
    const PointerDownEvent down2 = PointerDownEvent(
      pointer: 6,
      position: Offset(10, 10),
    );

    const PointerUpEvent up2 = PointerUpEvent(
      pointer: 6,
      position: Offset(11, 9),
    );

    LongPressGestureRecognizer longPress;
    bool longPressDown;
    bool longPressUp;

    setUp(() {
      longPress = LongPressGestureRecognizer();
      longPressDown = false;
      longPress.onAnyLongPressStart = (LongPressStartDetails details) {
        longPressDown = true;
      };
      longPressUp = false;
      longPress.onAnyLongPressEnd = (LongPressEndDetails details) {
        longPressUp = true;
      };
    });

    tearDown(() {
      longPress.dispose();
    });
    testGesture('Buttons change before acceptance should not prevent the next long press', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 300));
      tester.route(moveM);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up);
      expect(longPressUp, isFalse);

      // Second press
      longPress.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(longPressDown, isTrue);
      tester.route(up2);
      expect(longPressUp, isTrue);
    });

    testGesture('Should cancel long press when buttons change after acceptance', (GestureTester tester) {
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(longPressDown, isTrue);
      tester.route(moveM);
      tester.route(up);
      expect(longPressUp, isFalse);
    });

    testGesture('Buttons change after acceptance should not prevent the next long press', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(moveM);
      expect(longPressDown, isTrue);
      tester.route(up);
      expect(longPressUp, isFalse);

      longPressDown = false;

      // Second press
      longPress.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(longPressDown, isTrue);
      tester.route(up2);
      expect(longPressUp, isTrue);
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

  group('Dispatch to different callbacks per buttons:', () {
    final List<String> recognized = <String>[];
    LongPressGestureRecognizer longPress;
    setUp(() {
      longPress = LongPressGestureRecognizer()
        ..onAnyLongPressStart = (LongPressStartDetails details) {
          recognized.add('anyStart ${details.buttons}');
        }
        ..onAnyLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
          recognized.add('anyUpdate ${details.buttons}');
        }
        ..onAnyLongPressEnd = (LongPressEndDetails details) {
          recognized.add('anyEnd ${details.buttons}');
        }
        ..onLongPressStart = (LongPressStartDetails details) {
          recognized.add('primaryStart ${details.buttons}');
        }
        ..onLongPress = () {
          recognized.add('primary');
        }
        ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
          recognized.add('primaryUpdate ${details.buttons}');
        }
        ..onLongPressEnd = (LongPressEndDetails details) {
          recognized.add('primaryEnd ${details.buttons}');
        }
        ..onLongPressUp = () {
          recognized.add('primaryUp');
        };
    });

    tearDown(() {
      longPress.dispose();
      recognized.clear();
    });

    testGesture('A primary long press should trigger any and primary', (GestureTester tester) {
      const PointerDownEvent down2 = PointerDownEvent(
        pointer: 2,
        buttons: kPrimaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerMoveEvent move2 = PointerMoveEvent(
        pointer: 2,
        buttons: kPrimaryButton,
        position: Offset(100, 200),
      );

      const PointerUpEvent up2 = PointerUpEvent(
        pointer: 2,
        position: Offset(100, 201),
      );

      longPress.addPointer(down2);
      tester.closeArena(2);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, <String>['anyStart 1', 'primaryStart 1', 'primary']);
      recognized.clear();

      tester.route(move2);
      expect(recognized, <String>['anyUpdate 1', 'primaryUpdate 1']);
      recognized.clear();

      tester.route(up2);
      expect(recognized, <String>['anyEnd 1', 'primaryEnd 1', 'primaryUp']);
    });

    testGesture('A secondary long press should trigger any', (GestureTester tester) {
      const PointerDownEvent down2 = PointerDownEvent(
        pointer: 2,
        buttons: kSecondaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerMoveEvent move2 = PointerMoveEvent(
        pointer: 2,
        buttons: kSecondaryButton,
        position: Offset(100, 200),
      );

      const PointerUpEvent up2 = PointerUpEvent(
        pointer: 2,
        position: Offset(100, 201),
      );

      longPress.addPointer(down2);
      tester.closeArena(2);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, <String>['anyStart 2']);
      recognized.clear();

      tester.route(move2);
      expect(recognized, <String>['anyUpdate 2']);
      recognized.clear();

      tester.route(up2);
      expect(recognized, <String>['anyEnd 2']);
    });

    testGesture('A long press with 0 buttons should trigger nothing', (GestureTester tester) {
      const PointerDownEvent down2 = PointerDownEvent(
        pointer: 1,
        buttons: 0,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up2 = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      longPress.addPointer(down2);
      tester.closeArena(2);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up2);
      expect(recognized, <String>[]);
    });

    testGesture('A long press with 2 buttons should trigger nothing', (GestureTester tester) {
      const PointerDownEvent down2 = PointerDownEvent(
        pointer: 1,
        buttons: kPrimaryButton | kSecondaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up2 = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      longPress.addPointer(down2);
      tester.closeArena(2);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up2);
      expect(recognized, <String>[]);
    });
  });
}
