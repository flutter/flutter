// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

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
        events.add('cancel');
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
}
