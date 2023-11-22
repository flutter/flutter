// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('acceptGesture tolerates a null lastPendingEventTimestamp', () {
    // Regression test for https://github.com/flutter/flutter/issues/112403
    // and b/249091367
    final DragGestureRecognizer recognizer = VerticalDragGestureRecognizer();
    const PointerDownEvent event = PointerDownEvent(timeStamp: Duration(days: 10));

    expect(recognizer.debugLastPendingEventTimestamp, null);

    recognizer.addAllowedPointer(event);
    expect(recognizer.debugLastPendingEventTimestamp, event.timeStamp);

    // Normal case: acceptGesture called and we have a last timestamp set.
    recognizer.acceptGesture(event.pointer);
    expect(recognizer.debugLastPendingEventTimestamp, null);

    // Reject the gesture to reset state and allow accepting it again.
    recognizer.rejectGesture(event.pointer);
    expect(recognizer.debugLastPendingEventTimestamp, null);

    // Not entirely clear how this can happen, but the bugs mentioned above show
    // we can end up in this state empircally.
    recognizer.acceptGesture(event.pointer);
    expect(recognizer.debugLastPendingEventTimestamp, null);
  });

  testGesture('do not crash on up event for a pending pointer after winning arena for another pointer', (GestureTester tester) {
    // Regression test for https://github.com/flutter/flutter/issues/75061.

    final VerticalDragGestureRecognizer v = VerticalDragGestureRecognizer()
      ..onStart = (_) { };
    final HorizontalDragGestureRecognizer h = HorizontalDragGestureRecognizer()
      ..onStart = (_) { };

    const PointerDownEvent down90 = PointerDownEvent(
      pointer: 90,
      position: Offset(10.0, 10.0),
    );

    const PointerUpEvent up90 = PointerUpEvent(
      pointer: 90,
      position: Offset(10.0, 10.0),
    );

    const PointerDownEvent down91 = PointerDownEvent(
      pointer: 91,
      position: Offset(20.0, 20.0),
    );

    const PointerUpEvent up91 = PointerUpEvent(
      pointer: 91,
      position: Offset(20.0, 20.0),
    );

    v.addPointer(down90);
    GestureBinding.instance.gestureArena.close(90);
    h.addPointer(down91);
    v.addPointer(down91);
    GestureBinding.instance.gestureArena.close(91);
    tester.async.flushMicrotasks();

    GestureBinding.instance.handleEvent(up90, HitTestEntry(MockHitTestTarget()));
    GestureBinding.instance.handleEvent(up91, HitTestEntry(MockHitTestTarget()));
  });

  testGesture('DragGestureRecognizer should not dispatch drag callbacks when it wins the arena if onlyAcceptDragOnThreshold is true and the threshold has not been met', (GestureTester tester) {
    final VerticalDragGestureRecognizer verticalDrag = VerticalDragGestureRecognizer();
    final List<String> dragCallbacks = <String>[];
    verticalDrag
      ..onlyAcceptDragOnThreshold = true
      ..onStart = (DragStartDetails details) {
        dragCallbacks.add('onStart');
      }
      ..onUpdate = (DragUpdateDetails details) {
        dragCallbacks.add('onUpdate');
      }
      ..onEnd = (DragEndDetails details) {
        dragCallbacks.add('onEnd');
      };

    const PointerDownEvent down1 = PointerDownEvent(
      pointer: 6,
      position: Offset(10.0, 10.0),
    );

    const PointerUpEvent up1 = PointerUpEvent(
      pointer: 6,
      position: Offset(10.0, 10.0),
    );

    verticalDrag.addPointer(down1);
    tester.closeArena(down1.pointer);
    tester.route(down1);
    tester.route(up1);
    expect(dragCallbacks.isEmpty, true);
    verticalDrag.dispose();
    dragCallbacks.clear();
  });

  testGesture('DragGestureRecognizer should dispatch drag callbacks when it wins the arena if onlyAcceptDragOnThreshold is false and the threshold has not been met', (GestureTester tester) {
    final VerticalDragGestureRecognizer verticalDrag = VerticalDragGestureRecognizer();
    final List<String> dragCallbacks = <String>[];
    verticalDrag
      ..onlyAcceptDragOnThreshold = false
      ..onStart = (DragStartDetails details) {
        dragCallbacks.add('onStart');
      }
      ..onUpdate = (DragUpdateDetails details) {
        dragCallbacks.add('onUpdate');
      }
      ..onEnd = (DragEndDetails details) {
        dragCallbacks.add('onEnd');
      };

    const PointerDownEvent down1 = PointerDownEvent(
      pointer: 6,
      position: Offset(10.0, 10.0),
    );

    const PointerUpEvent up1 = PointerUpEvent(
      pointer: 6,
      position: Offset(10.0, 10.0),
    );

    verticalDrag.addPointer(down1);
    tester.closeArena(down1.pointer);
    tester.route(down1);
    tester.route(up1);
    expect(dragCallbacks.isEmpty, false);
    expect(dragCallbacks, <String>['onStart', 'onEnd']);
    verticalDrag.dispose();
    dragCallbacks.clear();
  });

  group('Recognizers on different button filters:', () {
    final List<String> recognized = <String>[];
    late HorizontalDragGestureRecognizer primaryRecognizer;
    late HorizontalDragGestureRecognizer secondaryRecognizer;
    setUp(() {
      primaryRecognizer = HorizontalDragGestureRecognizer(
          allowedButtonsFilter: (int buttons) => kPrimaryButton == buttons)
        ..onStart = (DragStartDetails details) {
          recognized.add('onStartPrimary');
        };
      secondaryRecognizer = HorizontalDragGestureRecognizer(
          allowedButtonsFilter: (int buttons) => kSecondaryButton == buttons)
        ..onStart = (DragStartDetails details) {
          recognized.add('onStartSecondary');
        };
    });

    tearDown(() {
      recognized.clear();
      primaryRecognizer.dispose();
      secondaryRecognizer.dispose();
    });

    testGesture('Primary button works', (GestureTester tester) {
      const PointerDownEvent down1 = PointerDownEvent(
        pointer: 6,
        position: Offset(10.0, 10.0),
      );

      primaryRecognizer.addPointer(down1);
      secondaryRecognizer.addPointer(down1);
      tester.closeArena(down1.pointer);
      tester.route(down1);
      expect(recognized, <String>['onStartPrimary']);
    });

    testGesture('Secondary button works', (GestureTester tester) {
      const PointerDownEvent down1 = PointerDownEvent(
        pointer: 6,
        position: Offset(10.0, 10.0),
        buttons: kSecondaryMouseButton,
      );

      primaryRecognizer.addPointer(down1);
      secondaryRecognizer.addPointer(down1);
      tester.closeArena(down1.pointer);
      tester.route(down1);
      expect(recognized, <String>['onStartSecondary']);
    });
  });
}

class MockHitTestTarget implements HitTestTarget {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) { }
}
