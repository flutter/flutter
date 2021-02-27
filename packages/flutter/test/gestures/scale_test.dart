// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize scale gestures', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer();
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool didStartScale = false;
    Offset? updatedFocalPoint;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
      updatedFocalPoint = details.focalPoint;
    };

    double? updatedScale;
    double? updatedHorizontalScale;
    double? updatedVerticalScale;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedScale = details.scale;
      updatedHorizontalScale = details.horizontalScale;
      updatedVerticalScale = details.verticalScale;
      updatedFocalPoint = details.focalPoint;
    };

    bool didEndScale = false;
    scale.onEnd = (ScaleEndDetails details) {
      didEndScale = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    final TestPointer pointer1 = TestPointer(1);

    final PointerDownEvent down = pointer1.down(Offset.zero);
    scale.addPointer(down);
    tap.addPointer(down);

    tester.closeArena(1);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // One-finger panning
    tester.route(down);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer1.move(const Offset(20.0, 30.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Two-finger scaling
    final TestPointer pointer2 = TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    tap.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    tester.route(pointer2.move(const Offset(0.0, 10.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(10.0, 20.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    expect(updatedHorizontalScale, 2.0);
    expect(updatedVerticalScale, 2.0);
    updatedScale = null;
    updatedHorizontalScale = null;
    updatedVerticalScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Zoom out
    tester.route(pointer2.move(const Offset(15.0, 25.0)));
    expect(updatedFocalPoint, const Offset(17.5, 27.5));
    expect(updatedScale, 0.5);
    expect(updatedHorizontalScale, 0.5);
    expect(updatedVerticalScale, 0.5);
    expect(didTap, isFalse);

    // Horizontal scaling
    tester.route(pointer2.move(const Offset(0.0, 20.0)));
    expect(updatedHorizontalScale, 2.0);
    expect(updatedVerticalScale, 1.0);

    // Vertical scaling
    tester.route(pointer2.move(const Offset(10.0, 10.0)));
    expect(updatedHorizontalScale, 1.0);
    expect(updatedVerticalScale, 2.0);
    tester.route(pointer2.move(const Offset(15.0, 25.0)));
    updatedFocalPoint = null;
    updatedScale = null;

    // Three-finger scaling
    final TestPointer pointer3 = TestPointer(3);
    final PointerDownEvent down3 = pointer3.down(const Offset(25.0, 35.0));
    scale.addPointer(down3);
    tap.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    tester.route(pointer3.move(const Offset(55.0, 65.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(30.0, 40.0));
    updatedFocalPoint = null;
    expect(updatedScale, 5.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Return to original positions but with different fingers
    tester.route(pointer1.move(const Offset(25.0, 35.0)));
    tester.route(pointer2.move(const Offset(20.0, 30.0)));
    tester.route(pointer3.move(const Offset(15.0, 25.0)));
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer1.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue scaling with two fingers
    tester.route(pointer3.move(const Offset(10.0, 20.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;

    // Continue rotating with two fingers
    tester.route(pointer3.move(const Offset(30.0, 40.0)));
    expect(updatedFocalPoint, const Offset(25.0, 35.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;
    tester.route(pointer3.move(const Offset(10.0, 20.0)));
    expect(updatedFocalPoint, const Offset(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;

    tester.route(pointer2.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue panning with one finger
    tester.route(pointer3.move(Offset.zero));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, Offset.zero);
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;

    // We are done
    tester.route(pointer3.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    scale.dispose();
    tap.dispose();
  });

  testGesture('Rejects scale gestures from unallowed device kinds', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer(kind: PointerDeviceKind.touch);

    bool didStartScale = false;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
    };

    double? updatedScale;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedScale = details.scale;
    };

    final TestPointer mousePointer = TestPointer(1, PointerDeviceKind.mouse);

    final PointerDownEvent down = mousePointer.down(Offset.zero);
    scale.addPointer(down);
    tester.closeArena(1);

    // One-finger panning
    tester.route(down);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);

    // Using a mouse, the scale gesture shouldn't even start.
    tester.route(mousePointer.move(const Offset(20.0, 30.0)));
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);

    scale.dispose();
  });

  testGesture('Scale gestures starting from allowed device kinds cannot be ended from unallowed devices', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer(kind: PointerDeviceKind.touch);

    bool didStartScale = false;
    Offset? updatedFocalPoint;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
      updatedFocalPoint = details.focalPoint;
    };

    double? updatedScale;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedScale = details.scale;
      updatedFocalPoint = details.focalPoint;
    };

    bool didEndScale = false;
    scale.onEnd = (ScaleEndDetails details) {
      didEndScale = true;
    };

    final TestPointer touchPointer = TestPointer(1, PointerDeviceKind.touch);

    final PointerDownEvent down = touchPointer.down(Offset.zero);
    scale.addPointer(down);
    tester.closeArena(1);

    // One-finger panning
    tester.route(down);
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, Offset.zero);
    expect(didEndScale, isFalse);

    // The gesture can start using one touch finger.
    tester.route(touchPointer.move(const Offset(20.0, 30.0)));
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);

    // Two-finger scaling
    final TestPointer mousePointer = TestPointer(2, PointerDeviceKind.mouse);
    final PointerDownEvent down2 = mousePointer.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);

    // Mouse-generated events are ignored.
    expect(didEndScale, isFalse);
    expect(updatedScale, isNull);
    expect(didStartScale, isFalse);

    // Zoom in using a mouse doesn't work either.
    tester.route(mousePointer.move(const Offset(0.0, 10.0)));
    expect(updatedScale, isNull);
    expect(didEndScale, isFalse);

    scale.dispose();
  });

  testGesture('Scale gesture competes with drag', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();

    final List<String> log = <String>[];

    scale.onStart = (ScaleStartDetails details) { log.add('scale-start'); };
    scale.onUpdate = (ScaleUpdateDetails details) { log.add('scale-update'); };
    scale.onEnd = (ScaleEndDetails details) { log.add('scale-end'); };

    drag.onStart = (DragStartDetails details) { log.add('drag-start'); };
    drag.onEnd = (DragEndDetails details) { log.add('drag-end'); };

    final TestPointer pointer1 = TestPointer(1);

    final PointerDownEvent down = pointer1.down(const Offset(10.0, 10.0));
    scale.addPointer(down);
    drag.addPointer(down);

    tester.closeArena(1);
    expect(log, isEmpty);

    // Vertical moves are scales.
    tester.route(down);
    expect(log, isEmpty);

    // scale will win if focal point delta exceeds 18.0*2

    tester.route(pointer1.move(const Offset(10.0, 50.0))); // delta of 40.0 exceeds 18.0*2
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    final TestPointer pointer2 = TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    drag.addPointer(down2);

    tester.closeArena(2);
    expect(log, isEmpty);

    // Second pointer joins scale even though it moves horizontally.
    tester.route(down2);
    expect(log, <String>['scale-end']);
    log.clear();

    tester.route(pointer2.move(const Offset(30.0, 20.0)));
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    tester.route(pointer1.up());
    expect(log, equals(<String>['scale-end']));
    log.clear();

    tester.route(pointer2.up());
    expect(log, isEmpty);
    log.clear();

    // Horizontal moves are either drags or scales, depending on which wins first.
    // TODO(ianh): https://github.com/flutter/flutter/issues/11384
    // In this case, we move fast, so that the scale wins. If we moved slowly,
    // the horizontal drag would win, since it was added first.
    final TestPointer pointer3 = TestPointer(3);
    final PointerDownEvent down3 = pointer3.down(const Offset(30.0, 30.0));
    scale.addPointer(down3);
    drag.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);

    expect(log, isEmpty);

    tester.route(pointer3.move(const Offset(100.0, 30.0)));
    expect(log, equals(<String>['scale-start', 'scale-update']));
    log.clear();

    tester.route(pointer3.up());
    expect(log, equals(<String>['scale-end']));
    log.clear();

    scale.dispose();
    drag.dispose();
  });

  testGesture('Should recognize rotation gestures', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer();
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool didStartScale = false;
    Offset? updatedFocalPoint;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
      updatedFocalPoint = details.focalPoint;
    };

    double? updatedRotation;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedRotation = details.rotation;
      updatedFocalPoint = details.focalPoint;
    };

    bool didEndScale = false;
    scale.onEnd = (ScaleEndDetails details) {
      didEndScale = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    final TestPointer pointer1 = TestPointer(1);

    final PointerDownEvent down = pointer1.down(Offset.zero);
    scale.addPointer(down);
    tap.addPointer(down);

    tester.closeArena(1);
    expect(didStartScale, isFalse);
    expect(updatedRotation, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(down);
    tester.route(pointer1.move(const Offset(20.0, 30.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;

    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Two-finger scaling
    final TestPointer pointer2 = TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(30.0, 40.0));
    scale.addPointer(down2);
    tap.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedFocalPoint, isNull);
    expect(updatedRotation, isNull);
    expect(didStartScale, isFalse);


    // Zoom in
    tester.route(pointer2.move(const Offset(40.0, 50.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(30.0, 40.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Rotation
    tester.route(pointer2.move(const Offset(0.0, 10.0)));
    expect(updatedFocalPoint, const Offset(10.0, 20.0));
    updatedFocalPoint = null;
    expect(updatedRotation, math.pi);
    updatedRotation = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Three-finger scaling
    final TestPointer pointer3 = TestPointer(3);
    final PointerDownEvent down3 = pointer3.down(const Offset(25.0, 35.0));
    scale.addPointer(down3);
    tap.addPointer(down3);
    tester.closeArena(3);
    tester.route(down3);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedFocalPoint, isNull);
    expect(updatedRotation, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    tester.route(pointer3.move(const Offset(55.0, 65.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(25.0, 35.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Return to original positions but with different fingers
    tester.route(pointer1.move(const Offset(25.0, 35.0)));
    tester.route(pointer2.move(const Offset(20.0, 30.0)));
    tester.route(pointer3.move(const Offset(15.0, 25.0)));
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, const Offset(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    tester.route(pointer1.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedRotation, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);


    // Continue scaling with two fingers
    tester.route(pointer3.move(const Offset(10.0, 20.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Offset(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;

    // Continue rotating with two fingers
    tester.route(pointer3.move(const Offset(30.0, 40.0)));
    expect(updatedFocalPoint, const Offset(25.0, 35.0));
    updatedFocalPoint = null;
    expect(updatedRotation, - math.pi);
    updatedRotation = null;
    tester.route(pointer3.move(const Offset(10.0, 20.0)));
    expect(updatedFocalPoint, const Offset(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedRotation, 0.0);
    updatedRotation = null;

    tester.route(pointer2.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedRotation, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // We are done
    tester.route(pointer3.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedRotation, isNull);
    expect(didEndScale, isFalse);
    didEndScale = false;
    expect(didTap, isFalse);

    scale.dispose();
    tap.dispose();
  });

  testGesture('Scale gestures pointer count test', (GestureTester tester) {
    final ScaleGestureRecognizer scale = ScaleGestureRecognizer();

    int pointerCountOfStart = 0;
    scale.onStart = (ScaleStartDetails details) => pointerCountOfStart = details.pointerCount;

    int pointerCountOfUpdate = 0;
    scale.onUpdate = (ScaleUpdateDetails details) => pointerCountOfUpdate = details.pointerCount;

    int pointerCountOfEnd = 0;
    scale.onEnd = (ScaleEndDetails details) => pointerCountOfEnd = details.pointerCount;

    final TestPointer pointer1 = TestPointer(1);
    final PointerDownEvent down = pointer1.down(Offset.zero);
    scale.addPointer(down);
    tester.closeArena(1);

    // One-finger panning
    tester.route(down);
    // One pointer in contact with the screen now.
    expect(pointerCountOfStart, 1);
    tester.route(pointer1.move(const Offset(20.0, 30.0)));
    expect(pointerCountOfUpdate, 1);

    // Two-finger scaling
    final TestPointer pointer2 = TestPointer(2);
    final PointerDownEvent down2 = pointer2.down(const Offset(10.0, 20.0));
    scale.addPointer(down2);
    tester.closeArena(2);
    tester.route(down2);
    // Two pointers in contact with the screen now.
    expect(pointerCountOfEnd, 2); // Additional pointer down will trigger an end event.

    tester.route(pointer2.move(const Offset(0.0, 10.0)));
    expect(pointerCountOfStart, 2); // The new pointer move will trigger a start event.
    expect(pointerCountOfUpdate, 2);

    tester.route(pointer1.up());
    // One pointer in contact with the screen now.
    expect(pointerCountOfEnd, 1);

    tester.route(pointer2.move(const Offset(0.0, 10.0)));
    expect(pointerCountOfStart, 1);
    expect(pointerCountOfUpdate, 1);

    tester.route(pointer2.up());
    // No pointer in contact with the screen now.
    expect(pointerCountOfEnd, 0);

    scale.dispose();
  });
}
