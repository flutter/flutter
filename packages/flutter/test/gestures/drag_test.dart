// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize pan', (GestureTester tester) {
    final PanGestureRecognizer pan = PanGestureRecognizer();
    final TapGestureRecognizer tap = TapGestureRecognizer()..onTap = () {};

    bool didStartPan = false;
    pan.onStart = (_) {
      didStartPan = true;
    };

    Offset updatedScrollDelta;
    pan.onUpdate = (DragUpdateDetails details) {
      updatedScrollDelta = details.delta;
    };

    bool didEndPan = false;
    pan.onEnd = (DragEndDetails details) {
      didEndPan = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    tester.closeArena(5);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(down);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    // touch should give up when it hits kTouchSlop, which was 18.0 when this test was last updated.

    tester.route(pointer.move(const Offset(20.0, 20.0))); // moved 10 horizontally and 10 vertically which is 14 total
    expect(didStartPan, isFalse); // 14 < 18
    tester.route(pointer.move(const Offset(20.0, 30.0))); // moved 10 horizontally and 20 vertically which is 22 total
    expect(didStartPan, isTrue); // 22 > 18
    didStartPan = false;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, const Offset(0.0, -5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
    expect(didTap, isFalse);

    pan.dispose();
    tap.dispose();
  });

  testGesture('Should report most recent point to onStart by default', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..onStart = (_) {};

    Offset positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));
    drag.dispose();
    competingDrag.dispose();

    expect(positionAtOnStart, const Offset(30.0, 00.0));
  });

  testGesture('Should report most recent point to onStart with a start configuration', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..onStart = (_) {};

    Offset positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };
    Offset updateOffset;
    drag.onUpdate = (DragUpdateDetails details) {
      updateOffset = details.globalPosition;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));
    drag.dispose();
    competingDrag.dispose();

    expect(positionAtOnStart, const Offset(30.0, 0.0));
    expect(updateOffset, null);
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isTrue);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDelta, 10.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, 0.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

    drag.dispose();
  });

  testGesture('Should report original timestamps', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    Duration startTimestamp;
    drag.onStart = (DragStartDetails details) {
      startTimestamp = details.sourceTimeStamp;
    };

    Duration updatedTimestamp;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedTimestamp = details.sourceTimeStamp;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), timeStamp: const Duration(milliseconds: 100));
    drag.addPointer(down);
    tester.closeArena(5);
    expect(startTimestamp, isNull);

    tester.route(down);
    expect(startTimestamp, const Duration(milliseconds: 100));

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 200)));
    expect(updatedTimestamp, const Duration(milliseconds: 200));

    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 300)));
    expect(updatedTimestamp, const Duration(milliseconds: 300));

    drag.dispose();
  });

  // TODO(jslavitz): Revert these tests.

  testGesture('Should report initial down point to onStart with a down configuration', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer competingDrag = VerticalDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down
      ..onStart = (_) {};

    Offset positionAtOnStart;
    drag.onStart = (DragStartDetails details) {
      positionAtOnStart = details.globalPosition;
    };
    Offset updateOffset;
    Offset updateDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updateOffset = details.globalPosition;
      updateDelta = details.delta;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    competingDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);

    tester.route(pointer.move(const Offset(30.0, 0.0)));
    drag.dispose();
    competingDrag.dispose();

    expect(positionAtOnStart, const Offset(10.0, 10.0));

    // The drag is horizontal so we're going to ignore the vertical delta position
    // when calculating the new global position.
    expect(updateOffset, const Offset(30.0, 10.0));
    expect(updateDelta, const Offset(20.0, 0.0));
  });

  testGesture('Drag with multiple pointers in down behavior', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag1 =
    HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;
    final VerticalDragGestureRecognizer drag2 =
    VerticalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    final List<String> log = <String>[];
    drag1.onDown = (_) { log.add('drag1-down'); };
    drag1.onStart = (_) { log.add('drag1-start'); };
    drag1.onUpdate = (_) { log.add('drag1-update'); };
    drag1.onEnd = (_) { log.add('drag1-end'); };
    drag1.onCancel = () { log.add('drag1-cancel'); };
    drag2.onDown = (_) { log.add('drag2-down'); };
    drag2.onStart = (_) { log.add('drag2-start'); };
    drag2.onUpdate = (_) { log.add('drag2-update'); };
    drag2.onEnd = (_) { log.add('drag2-end'); };
    drag2.onCancel = () { log.add('drag2-cancel'); };

    final TestPointer pointer5 = TestPointer(5);
    final PointerDownEvent down5 = pointer5.down(const Offset(10.0, 10.0));
    drag1.addPointer(down5);
    drag2.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    log.add('-a');

    tester.route(pointer5.move(const Offset(100.0, 0.0)));
    log.add('-b');
    tester.route(pointer5.move(const Offset(50.0, 50.0)));
    log.add('-c');

    final TestPointer pointer6 = TestPointer(6);
    final PointerDownEvent down6 = pointer6.down(const Offset(20.0, 20.0));
    drag1.addPointer(down6);
    drag2.addPointer(down6);
    tester.closeArena(6);
    tester.route(down6);
    log.add('-d');

    tester.route(pointer5.move(const Offset(0.0, 100.0)));
    log.add('-e');
    tester.route(pointer5.move(const Offset(70.0, 70.0)));
    log.add('-f');

    tester.route(pointer5.up());
    tester.route(pointer6.up());

    drag1.dispose();
    drag2.dispose();

    expect(log, <String>[
      'drag1-down',
      'drag2-down',
      '-a',
      'drag2-cancel',
      'drag1-start',
      'drag1-update',
      '-b',
      'drag1-update',
      '-c',
      'drag2-down',
      'drag2-cancel',
      '-d',
      'drag1-update',
      '-e',
      'drag1-update',
      '-f',
      'drag1-end',
    ]);
  });

  testGesture('Clamp max velocity', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    Velocity velocity;
    double primaryVelocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
      primaryVelocity = details.primaryVelocity;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 10)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 11)));
    tester.route(pointer.move(const Offset(40.0, 25.0), timeStamp: const Duration(milliseconds: 12)));
    tester.route(pointer.move(const Offset(50.0, 25.0), timeStamp: const Duration(milliseconds: 13)));
    tester.route(pointer.move(const Offset(60.0, 25.0), timeStamp: const Duration(milliseconds: 14)));
    tester.route(pointer.move(const Offset(70.0, 25.0), timeStamp: const Duration(milliseconds: 15)));
    tester.route(pointer.move(const Offset(80.0, 25.0), timeStamp: const Duration(milliseconds: 16)));
    tester.route(pointer.move(const Offset(90.0, 25.0), timeStamp: const Duration(milliseconds: 17)));
    tester.route(pointer.move(const Offset(100.0, 25.0), timeStamp: const Duration(milliseconds: 18)));
    tester.route(pointer.move(const Offset(110.0, 25.0), timeStamp: const Duration(milliseconds: 19)));
    tester.route(pointer.move(const Offset(120.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 20)));
    expect(velocity.pixelsPerSecond.dx, inInclusiveRange(0.99 * kMaxFlingVelocity, kMaxFlingVelocity));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));
    expect(primaryVelocity, velocity.pixelsPerSecond.dx);

    drag.dispose();
  });

  testGesture('Synthesized pointer events are ignored for velocity tracking', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    Velocity velocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
    };

    final TestPointer pointer = TestPointer(1);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(1);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 30)));
    tester.route(pointer.move(const Offset(40.0, 25.0), timeStamp: const Duration(milliseconds: 40)));
    tester.route(pointer.move(const Offset(50.0, 25.0), timeStamp: const Duration(milliseconds: 50)));
    tester.route(const PointerMoveEvent(
      pointer: 1,
      // Simulate a small synthesized wobble which would have slowed down the
      // horizontal velocity from 1 px/ms and introduced a slight vertical velocity.
      position: Offset(51.0, 26.0),
      timeStamp: Duration(milliseconds: 60),
      synthesized: true,
    ));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 70)));
    expect(velocity.pixelsPerSecond.dx, moreOrLessEquals(1000.0));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));

    drag.dispose();
  });

  /// Checks that quick flick gestures with 1 down, 2 move and 1 up pointer
  /// events still have a velocity
  testGesture('Quick flicks have velocity', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    Velocity velocity;
    drag.onEnd = (DragEndDetails details) {
      velocity = details.velocity;
    };

    final TestPointer pointer = TestPointer(1);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 25.0), timeStamp: const Duration(milliseconds: 10));
    drag.addPointer(down);
    tester.closeArena(1);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 25.0), timeStamp: const Duration(milliseconds: 20)));
    tester.route(pointer.move(const Offset(30.0, 25.0), timeStamp: const Duration(milliseconds: 30)));
    tester.route(pointer.up(timeStamp: const Duration(milliseconds: 40)));
    // 3 events moving by 10px every 10ms = 1000px/s.
    expect(velocity.pixelsPerSecond.dx, moreOrLessEquals(1000.0));
    expect(velocity.pixelsPerSecond.dy, moreOrLessEquals(0.0));

    drag.dispose();
  });

  testGesture('Drag details', (GestureTester tester) {
    expect(DragDownDetails(), hasOneLineDescription);
    expect(DragStartDetails(), hasOneLineDescription);
    expect(DragUpdateDetails(globalPosition: Offset.zero), hasOneLineDescription);
    expect(DragEndDetails(), hasOneLineDescription);
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    Offset updateDelta;
    double updatePrimaryDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updateDelta = details.delta;
      updatePrimaryDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);

    expect(didStartDrag, isFalse);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(down);
    expect(didStartDrag, isTrue);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isFalse);
    didStartDrag = false;

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updateDelta, const Offset(10.0, 0.0));
    expect(updatePrimaryDelta, 10.0);
    expect(didEndDrag, isFalse);
    updateDelta = null;
    updatePrimaryDelta = null;

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updateDelta, const Offset(0.0, 0.0));
    expect(updatePrimaryDelta, 0.0);
    expect(didEndDrag, isFalse);
    updateDelta = null;
    updatePrimaryDelta = null;

    tester.route(pointer.up());
    expect(didStartDrag, isFalse);
    expect(updateDelta, isNull);
    expect(updatePrimaryDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

    drag.dispose();
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer() ..dragStartBehavior = DragStartBehavior.down;

    Offset latestGlobalPosition;
    drag.onStart = (DragStartDetails details) {
      latestGlobalPosition = details.globalPosition;
    };
    Offset latestDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      latestGlobalPosition = details.globalPosition;
      latestDelta = details.delta;
    };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    drag.addPointer(down);
    tester.closeArena(5);

    tester.route(down);
    expect(latestGlobalPosition, const Offset(10.0, 10.0));
    expect(latestDelta, isNull);

    tester.route(pointer.move(const Offset(20.0, 25.0)));
    expect(latestGlobalPosition, const Offset(20.0, 25.0));
    expect(latestDelta, const Offset(10.0, 0.0));

    tester.route(pointer.move(const Offset(0.0, 45.0)));
    expect(latestGlobalPosition, const Offset(0.0, 45.0));
    expect(latestDelta, const Offset(-20.0, 0.0));

    tester.route(pointer.up());
    drag.dispose();
  });

  testGesture('Can filter drags based on device kind', (GestureTester tester) {
    final HorizontalDragGestureRecognizer drag =
        HorizontalDragGestureRecognizer(
            kind: PointerDeviceKind.mouse,
        )
        ..dragStartBehavior = DragStartBehavior.down;

    bool didStartDrag = false;
    drag.onStart = (_) {
      didStartDrag = true;
    };

    double updatedDelta;
    drag.onUpdate = (DragUpdateDetails details) {
      updatedDelta = details.primaryDelta;
    };

    bool didEndDrag = false;
    drag.onEnd = (DragEndDetails details) {
      didEndDrag = true;
    };

    // Using a touch pointer to drag shouldn't be recognized.
    final TestPointer touchPointer = TestPointer(5, PointerDeviceKind.touch);
    final PointerDownEvent touchDown = touchPointer.down(const Offset(10.0, 10.0));
    drag.addPointer(touchDown);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchDown);
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchPointer.move(const Offset(20.0, 25.0)));
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(touchPointer.up());
    // Still doesn't recognize the drag because it's coming from a touch pointer.
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    // Using a mouse pointer to drag should be recognized.
    final TestPointer mousePointer = TestPointer(5, PointerDeviceKind.mouse);
    final PointerDownEvent mouseDown = mousePointer.down(const Offset(10.0, 10.0));
    drag.addPointer(mouseDown);
    tester.closeArena(5);
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(mouseDown);
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDelta, isNull);
    expect(didEndDrag, isFalse);

    tester.route(mousePointer.move(const Offset(20.0, 25.0)));
    expect(didStartDrag, isFalse);
    expect(updatedDelta, 10.0);
    updatedDelta = null;
    expect(didEndDrag, isFalse);

    tester.route(mousePointer.up());
    expect(didStartDrag, isFalse);
    expect(updatedDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

    drag.dispose();
  });

  group('Enforce consistent-button restriction:', () {
    PanGestureRecognizer pan;
    TapGestureRecognizer tap;
    final List<String> logs = <String>[];

    setUp(() {
      tap = TapGestureRecognizer()
        ..onTap = () {}; // Need a callback to enable competition
      pan = PanGestureRecognizer()
        ..onStart = (DragStartDetails details) {
          logs.add('start');
        }
        ..onDown = (DragDownDetails details) {
          logs.add('down');
        }
        ..onUpdate = (DragUpdateDetails details) {
          logs.add('update');
        }
        ..onCancel = () {
          logs.add('cancel');
        }
        ..onEnd = (DragEndDetails details) {
          logs.add('end');
        };
    });

    tearDown(() {
      pan.dispose();
      tap.dispose();
      logs.clear();
    });

    testGesture('Button change before acceptance should lead to immediate cancel', (GestureTester tester) {
      final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
      pan.addPointer(down);
      tap.addPointer(down);
      tester.closeArena(5);

      tester.route(down);
      expect(logs, <String>['down']);
      // Move out of slop so make sure button changes takes priority over slops
      tester.route(pointer.move(const Offset(30.0, 30.0), buttons: kSecondaryButton));
      expect(logs, <String>['down', 'cancel']);

      tester.route(pointer.up());
    });

    testGesture('Button change before acceptance should not prevent the next drag', (GestureTester tester) {
      { // First drag (which is canceled)
        final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
        final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
        pan.addPointer(down);
        tap.addPointer(down);
        tester.closeArena(down.pointer);

        tester.route(down);
        tester.route(pointer.move(const Offset(10.0, 10.0), buttons: kSecondaryButton));
        tester.route(pointer.up());
        expect(logs, <String>['down', 'cancel']);
      }
      logs.clear();

      final TestPointer pointer2 = TestPointer(6, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 10.0));
      pan.addPointer(down2);
      tap.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      expect(logs, <String>['down']);

      tester.route(pointer2.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);

      tester.route(pointer2.up());
      expect(logs, <String>['down', 'start', 'end']);
    });

    testGesture('Button change after acceptance should lead to immediate end', (GestureTester tester) {
      final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
      pan.addPointer(down);
      tap.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(logs, <String>['down']);
      tester.route(pointer.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);
      tester.route(pointer.move(const Offset(30.0, 30.0), buttons: kSecondaryButton));
      expect(logs, <String>['down', 'start', 'end']);

      // Make sure no further updates are sent
      tester.route(pointer.move(const Offset(50.0, 50.0)));
      expect(logs, <String>['down', 'start', 'end']);

      tester.route(pointer.up());
    });

    testGesture('Button change after acceptance should not prevent the next drag', (GestureTester tester) {
      { // First drag (which is canceled)
        final TestPointer pointer = TestPointer(5, PointerDeviceKind.mouse, kPrimaryButton);
        final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
        pan.addPointer(down);
        tap.addPointer(down);
        tester.closeArena(down.pointer);

        tester.route(down);

        tester.route(pointer.move(const Offset(30.0, 30.0)));

        tester.route(pointer.move(const Offset(30.0, 31.0), buttons: kSecondaryButton));
        tester.route(pointer.up());
        expect(logs, <String>['down', 'start', 'end']);
      }
      logs.clear();

      final TestPointer pointer2 = TestPointer(6, PointerDeviceKind.mouse, kPrimaryButton);
      final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 10.0));
      pan.addPointer(down2);
      tap.addPointer(down2);
      tester.closeArena(down2.pointer);
      tester.route(down2);
      expect(logs, <String>['down']);

      tester.route(pointer2.move(const Offset(30.0, 30.0)));
      expect(logs, <String>['down', 'start']);

      tester.route(pointer2.up());
      expect(logs, <String>['down', 'start', 'end']);
    });
  });

  group('Recognizers listening on different buttons do not form competition:', () {
    // This test is assisted by tap recognizers. If a tap gesture has
    // no competing recognizers, a pointer down event triggers its onTapDown
    // immediately; if there are competitors, onTapDown is triggered after a
    // timeout.
    // The following tests make sure that drag recognizers do not form
    // competition with a tap gesture recognizer listening on a different button.

    final List<String> recognized = <String>[];
    TapGestureRecognizer tapPrimary;
    TapGestureRecognizer tapSecondary;
    PanGestureRecognizer pan;
    setUp(() {
      tapPrimary = TapGestureRecognizer()
        ..onTapDown = (TapDownDetails details) {
          recognized.add('tapPrimary');
        };
      tapSecondary = TapGestureRecognizer()
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('tapSecondary');
        };
      pan = PanGestureRecognizer()
        ..onStart = (_) {
          recognized.add('drag');
        };
    });

    tearDown(() {
      recognized.clear();
      tapPrimary.dispose();
      tapSecondary.dispose();
      pan.dispose();
    });

    testGesture('A primary pan recognizer does not form competition with a secondary tap recognizer', (GestureTester tester) {
      final TestPointer pointer = TestPointer(
        1,
        PointerDeviceKind.touch,
        0,
        kSecondaryButton,
      );
      final PointerDownEvent down = pointer.down(const Offset(10, 10));
      pan.addPointer(down);
      tapSecondary.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(recognized, <String>['tapSecondary']);
    });

    testGesture('A primary pan recognizer forms competition with a primary tap recognizer', (GestureTester tester) {
      final TestPointer pointer = TestPointer(
        1,
        PointerDeviceKind.touch,
        kPrimaryButton,
      );
      final PointerDownEvent down = pointer.down(const Offset(10, 10));
      pan.addPointer(down);
      tapPrimary.addPointer(down);
      tester.closeArena(down.pointer);

      tester.route(down);
      expect(recognized, <String>[]);

      tester.route(pointer.up());
      expect(recognized, <String>['tapPrimary']);
    });
  });

  testGesture('A secondary drag should not trigger primary', (GestureTester tester) {
    final List<String> recognized = <String>[];
    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTap = () {}; // Need a listener to enable competition.
    final PanGestureRecognizer pan = PanGestureRecognizer()
      ..onDown = (DragDownDetails details) {
        recognized.add('primaryDown');
      }
      ..onStart = (DragStartDetails details) {
        recognized.add('primaryStart');
      }
      ..onUpdate = (DragUpdateDetails details) {
        recognized.add('primaryUpdate');
      }
      ..onEnd = (DragEndDetails details) {
        recognized.add('primaryEnd');
      }
      ..onCancel = () {
        recognized.add('primaryCancel');
      };

    final TestPointer pointer = TestPointer(
      5,
      PointerDeviceKind.touch,
      0,
      kSecondaryButton,
    );

    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(20.0, 30.0)));
    tester.route(pointer.move(const Offset(20.0, 25.0)));
    tester.route(pointer.up());
    expect(recognized, <String>[]);
    recognized.clear();

    pan.dispose();
    tap.dispose();
    recognized.clear();
  });
}
