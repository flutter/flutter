// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gestures/gesture_tester.dart';

// Anything longer than [kDoubleTapTimeout] will reset the consecutive tap count.
final Duration kConsecutiveTapDelay = kDoubleTapTimeout ~/ 2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> events;
  late TapAndDragGestureRecognizer tapAndDrag;

  setUp(() {
    events = <String>[];
    tapAndDrag = TapAndDragGestureRecognizer()
      ..dragStartBehavior = DragStartBehavior.down
      ..onTapDown = (TapDownDetails details, TapStatus status) {
        events.add('down#${status.consecutiveTapCount}');
      }
      ..onTapUp = (TapUpDetails details, TapStatus status) {
        events.add('up#${status.consecutiveTapCount}');
      }
      ..onTapCancel = () {
        events.add('tapcancel');
      }
      ..onStart = (DragStartDetails details, TapStatus status) {
        events.add('dragstart#${status.consecutiveTapCount}');
      }
      ..onUpdate = (DragUpdateDetails details, TapStatus status) {
        events.add('dragupdate#${status.consecutiveTapCount}');
      }
      ..onEnd = (DragEndDetails details, TapStatus status) {
        events.add('dragend#${status.consecutiveTapCount}');
      }
      ..onDragCancel = () {
        events.add('dragcancel');
      };
  });

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = PointerDownEvent(
    pointer: 1,
    position: Offset(10.0, 10.0),
  );

  const PointerUpEvent up1 = PointerUpEvent(
    pointer: 1,
    position: Offset(11.0, 9.0),
  );

  const PointerCancelEvent cancel1 = PointerCancelEvent(
    pointer: 1,
  );

  // Down/up pair 2: normal tap sequence close to pair 1
  const PointerDownEvent down2 = PointerDownEvent(
    pointer: 2,
    position: Offset(12.0, 12.0),
  );

  const PointerUpEvent up2 = PointerUpEvent(
    pointer: 2,
    position: Offset(13.0, 11.0),
  );

  // Down/up pair 3: normal tap sequence close to pair 1
  const PointerDownEvent down3 = PointerDownEvent(
    pointer: 3,
    position: Offset(12.0, 12.0),
  );

  const PointerUpEvent up3 = PointerUpEvent(
    pointer: 3,
    position: Offset(13.0, 11.0),
  );

  // Down/up pair 4: normal tap sequence far away from pair 1
  const PointerDownEvent down4 = PointerDownEvent(
    pointer: 4,
    position: Offset(130.0, 130.0),
  );

  const PointerUpEvent up4 = PointerUpEvent(
    pointer: 4,
    position: Offset(131.0, 129.0),
  );

  // Down/move/up sequence 5: intervening motion
  const PointerDownEvent down5 = PointerDownEvent(
    pointer: 5,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move5 = PointerMoveEvent(
    pointer: 5,
    position: Offset(25.0, 25.0),
  );

  const PointerUpEvent up5 = PointerUpEvent(
    pointer: 5,
    position: Offset(25.0, 25.0),
  );

  testGesture('Recognizes consecutive taps', (GestureTester tester) {
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);

    events.clear();
    tester.async.elapse(kConsecutiveTapDelay);
    tapAndDrag.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance.gestureArena.sweep(2);
    expect(events, <String>['down#2', 'dragcancel', 'up#2']);

    events.clear();
    tester.async.elapse(kConsecutiveTapDelay);
    tapAndDrag.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);
    tester.route(up3);
    GestureBinding.instance.gestureArena.sweep(3);
    expect(events, <String>['down#3', 'dragcancel', 'up#3']);
  });

  testGesture('Resets if times out in between taps', (GestureTester tester) {
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 1000));
    tapAndDrag.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance.gestureArena.sweep(2);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);
  });

  testGesture('Resets if taps are far apart', (GestureTester tester) {
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    tapAndDrag.addPointer(down4);
    tester.closeArena(4);
    tester.route(down4);
    tester.route(up4);
    GestureBinding.instance.gestureArena.sweep(4);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);
  });

  testGesture('Should recognize drag', (GestureTester tester) {
    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(down);
    tester.closeArena(5);
    tester.route(down);
    tester.route(pointer.move(const Offset(40.0, 45.0)));
    tester.route(pointer.up());
    GestureBinding.instance.gestureArena.sweep(5);
    expect(events, <String>['down#1', 'tapcancel', 'dragstart#1', 'dragupdate#1', 'dragend#1']);
  });

  testGesture('Recognizes consecutive taps + drag', (GestureTester tester) {
    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent downA = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(downA);
    tester.closeArena(5);
    tester.route(downA);
    tester.route(pointer.up());
    GestureBinding.instance.gestureArena.sweep(5);

    tester.async.elapse(kConsecutiveTapDelay);

    final PointerDownEvent downB = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(downB);
    tester.closeArena(5);
    tester.route(downB);
    tester.route(pointer.up());
    GestureBinding.instance.gestureArena.sweep(5);

    tester.async.elapse(kConsecutiveTapDelay);

    final PointerDownEvent downC = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(downC);
    tester.closeArena(5);
    tester.route(downC);
    tester.route(pointer.move(const Offset(40.0, 45.0)));
    tester.route(pointer.up());
    expect(events, <String>[
      'down#1',
      'dragcancel',
      'up#1',
      'down#2',
      'dragcancel',
      'up#2',
      'down#3',
      'tapcancel',
      'dragstart#3',
      'dragupdate#3',
      'dragend#3']);
  });

  testGesture('Beats LongPressGestureRecognizer on a consecutive tap greater than one', (GestureTester tester) {
    final LongPressGestureRecognizer longpress = LongPressGestureRecognizer()
      ..onLongPressStart = (LongPressStartDetails details) {
        events.add('longpressstart');
      }
      ..onLongPressMoveUpdate =  (LongPressMoveUpdateDetails details) {
        events.add('longpressmoveupdate');
      }
      ..onLongPressEnd = (LongPressEndDetails details) {
        events.add('longpressend');
      }
      ..onLongPressCancel = () {
        events.add('longpresscancel');
      };

    final TestPointer pointer = TestPointer(5);
    final PointerDownEvent downA = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(downA);
    longpress.addPointer(downA);
    tester.closeArena(5);
    tester.route(downA);
    tester.route(pointer.up());
    GestureBinding.instance.gestureArena.sweep(5);

    tester.async.elapse(kConsecutiveTapDelay);

    final PointerDownEvent downB = pointer.down(const Offset(10.0, 10.0));
    tapAndDrag.addPointer(downB);
    longpress.addPointer(downB);
    tester.closeArena(5);
    tester.route(downB);

    tester.async.elapse(const Duration(milliseconds: 500));

    tester.route(pointer.move(const Offset(40.0, 45.0)));
    tester.route(pointer.up());
    expect(events, <String>[
      'dragcancel',
      'longpresscancel',
      'down#1',
      'up#1',
      'down#2',
      'tapcancel',
      'dragstart#2',
      'dragupdate#2',
      'dragend#2']);
  });

  testGesture('Fires cancel and resets when pointer dragged past slop tolerance', (GestureTester tester) {
    tapAndDrag.addPointer(down5);
    tester.closeArena(5);
    tester.route(down5);
    tester.route(move5);
    tester.route(up5);
    GestureBinding.instance.gestureArena.sweep(5);
    expect(events, <String>['down#1', 'tapcancel', 'dragcancel']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 1000));
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);
  });

  testGesture('Fires cancel and resets for PointerCancelEvent', (GestureTester tester) {
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(cancel1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['down#1', 'tapcancel', 'dragcancel']);

    events.clear();
    tester.async.elapse(const Duration(milliseconds: 100));
    tapAndDrag.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    tester.route(up2);
    GestureBinding.instance.gestureArena.sweep(2);
    expect(events, <String>['down#1', 'dragcancel', 'up#1']);
  });

  testGesture('Fires cancel if competing recognizer declares victory', (GestureTester tester) {
    final WinningGestureRecognizer winner = WinningGestureRecognizer();
    winner.addPointer(down1);
    tapAndDrag.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    tester.route(up1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(events, <String>['tapcancel', 'dragcancel']);
  });
}

class WinningGestureRecognizer extends PrimaryPointerGestureRecognizer {
  @override
  String get debugDescription => 'winner';

  @override
  void handlePrimaryPointer(PointerEvent event) {
    resolve(GestureDisposition.accepted);
  }
}
