// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

// Down/move/up pair 1: normal tap sequence
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

// Down/up pair 2: normal tap sequence far away from pair 1
const PointerDownEvent down2 = PointerDownEvent(
  pointer: 6,
  position: Offset(10, 10),
);

const PointerUpEvent up2 = PointerUpEvent(
  pointer: 6,
  position: Offset(11, 9),
);

// Down/up pair 3: tap sequence with secondary button
const PointerDownEvent down3 = PointerDownEvent(
  pointer: 7,
  position: Offset(30, 30),
  buttons: kSecondaryButton,
);

const PointerUpEvent up3 = PointerUpEvent(
  pointer: 7,
  position: Offset(31, 29),
);

// Down/up pair 4: tap sequence with tertiary button
const PointerDownEvent down4 = PointerDownEvent(
  pointer: 8,
  position: Offset(42, 24),
  buttons: kTertiaryButton,
);

const PointerUpEvent up4 = PointerUpEvent(
  pointer: 8,
  position: Offset(43, 23),
);

void main() {
  setUp(ensureGestureBinding);

  group('Long press', () {
    late LongPressGestureRecognizer longPress;
    late bool longPressDown;
    late bool longPressUp;

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

    testGesture('Should recognize long press with altered duration', (GestureTester tester) {
      longPress = LongPressGestureRecognizer(duration: const Duration(milliseconds: 100));
      longPressDown = false;
      longPress.onLongPress = () {
        longPressDown = true;
      };
      longPressUp = false;
      longPress.onLongPressUp = () {
        longPressUp = true;
      };
      longPress.addPointer(down);
      tester.closeArena(5);
      expect(longPressDown, isFalse);
      tester.route(down);
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 50));
      expect(longPressDown, isFalse);
      tester.async.elapse(const Duration(milliseconds: 50));
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
        buttons: kSecondaryMouseButton | kTertiaryButton,
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
        buttons: kTertiaryButton,
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
    late LongPressGestureRecognizer longPressDrag;
    late bool longPressStart;
    late bool longPressUp;
    Offset? longPressDragUpdate;

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

  group('Enforce consistent-button restriction:', () {
    // In sequence between `down` and `up` but with buttons changed
    const PointerMoveEvent moveR = PointerMoveEvent(
      pointer: 5,
      buttons: kSecondaryButton,
      position: Offset(10, 10),
    );

    final List<String> recognized = <String>[];

    late LongPressGestureRecognizer longPress;

    setUp(() {
      longPress = LongPressGestureRecognizer()
        ..onLongPressStart = (LongPressStartDetails details) {
          recognized.add('start');
        }
        ..onLongPressEnd = (LongPressEndDetails details) {
          recognized.add('end');
        };
    });

    tearDown(() {
      longPress.dispose();
      recognized.clear();
    });

    testGesture('Should cancel long press when buttons change before acceptance', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 300));
      tester.route(moveR);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up);
      expect(recognized, <String>[]);
    });

    testGesture('Buttons change before acceptance should not prevent the next long press', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 300));
      tester.route(moveR);
      tester.async.elapse(const Duration(milliseconds: 700));
      tester.route(up);
      recognized.clear();

      // Second press
      longPress.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(recognized, <String>['start']);
      recognized.clear();

      tester.route(up2);
      expect(recognized, <String>['end']);
    });

    testGesture('Should cancel long press when buttons change after acceptance', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(recognized, <String>['start']);
      recognized.clear();

      tester.route(moveR);
      expect(recognized, <String>[]);
      tester.route(up);
      expect(recognized, <String>[]);
    });

    testGesture('Buttons change after acceptance should not prevent the next long press', (GestureTester tester) {
      // First press
      longPress.addPointer(down);
      tester.closeArena(down.pointer);
      tester.route(down);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(moveR);
      tester.route(up);
      recognized.clear();

      // Second press
      longPress.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(recognized, <String>['start']);
      recognized.clear();

      tester.route(up2);
      expect(recognized, <String>['end']);
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

  group('Recognizers listening on different buttons do not form competition:', () {
    // This test is assisted by tap recognizers. If a tap gesture has
    // no competing recognizers, a pointer down event triggers its onTapDown
    // immediately; if there are competitors, onTapDown is triggered after a
    // timeout.
    // The following tests make sure that long press recognizers do not form
    // competition with a tap gesture recognizer listening on a different button.

    final List<String> recognized = <String>[];
    late TapGestureRecognizer tapPrimary;
    late TapGestureRecognizer tapSecondary;
    late LongPressGestureRecognizer longPress;
    setUp(() {
      tapPrimary = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('tapPrimary');
        };
      tapSecondary = TapGestureRecognizer()
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('tapSecondary');
        };
      longPress = LongPressGestureRecognizer()
        ..onLongPressStart = (_) {
          recognized.add('longPress');
        };
    });

    tearDown(() {
      recognized.clear();
      tapPrimary.dispose();
      tapSecondary.dispose();
      longPress.dispose();
    });

    testGesture('A primary long press recognizer does not form competition with a secondary tap recognizer', (GestureTester tester) {
      longPress.addPointer(down3);
      tapSecondary.addPointer(down3);
      tester.closeArena(down3.pointer);

      tester.route(down3);
      expect(recognized, <String>['tapSecondary']);
    });

    testGesture('A primary long press recognizer forms competition with a primary tap recognizer', (GestureTester tester) {
      longPress.addPointer(down);
      tapPrimary.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(recognized, <String>[]);

      tester.route(up);
      expect(recognized, <String>['tapPrimary']);
    });
  });

  testGesture('A secondary long press should not trigger primary', (GestureTester tester) {
    final List<String> recognized = <String>[];
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer()
      ..onLongPressStart = (LongPressStartDetails details) {
        recognized.add('primaryStart');
      }
      ..onLongPress = () {
        recognized.add('primary');
      }
      ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
        recognized.add('primaryUpdate');
      }
      ..onLongPressEnd = (LongPressEndDetails details) {
        recognized.add('primaryEnd');
      }
      ..onLongPressUp = () {
        recognized.add('primaryUp');
      };

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
    tester.route(move2);
    tester.route(up2);
    expect(recognized, <String>[]);
    longPress.dispose();
    recognized.clear();
  });

  testGesture('A tertiary long press should not trigger primary or secondary', (GestureTester tester) {
    final List<String> recognized = <String>[];
    final LongPressGestureRecognizer longPress = LongPressGestureRecognizer()
      ..onLongPressStart = (LongPressStartDetails details) {
        recognized.add('primaryStart');
      }
      ..onLongPress = () {
        recognized.add('primary');
      }
      ..onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
        recognized.add('primaryUpdate');
      }
      ..onLongPressEnd = (LongPressEndDetails details) {
        recognized.add('primaryEnd');
      }
      ..onLongPressUp = () {
        recognized.add('primaryUp');
      }
      ..onSecondaryLongPressStart = (LongPressStartDetails details) {
        recognized.add('secondaryStart');
      }
      ..onSecondaryLongPress = () {
        recognized.add('secondary');
      }
      ..onSecondaryLongPressMoveUpdate = (LongPressMoveUpdateDetails details) {
        recognized.add('secondaryUpdate');
      }
      ..onSecondaryLongPressEnd = (LongPressEndDetails details) {
        recognized.add('secondaryEnd');
      }
      ..onSecondaryLongPressUp = () {
        recognized.add('secondaryUp');
      };

    const PointerDownEvent down2 = PointerDownEvent(
      pointer: 2,
      buttons: kTertiaryButton,
      position: Offset(30.0, 30.0),
    );

    const PointerMoveEvent move2 = PointerMoveEvent(
      pointer: 2,
      buttons: kTertiaryButton,
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
    tester.route(move2);
    tester.route(up2);
    expect(recognized, <String>[]);
    longPress.dispose();
    recognized.clear();
  });
}
