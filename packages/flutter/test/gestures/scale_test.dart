// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('Should recognize scale gestures', (GestureTester tester) {
    ScaleGestureRecognizer scale = new ScaleGestureRecognizer();
    TapGestureRecognizer tap = new TapGestureRecognizer();

    bool didStartScale = false;
    Point updatedFocalPoint;
    scale.onStart = (ScaleStartDetails details) {
      didStartScale = true;
      updatedFocalPoint = details.focalPoint;
    };

    double updatedScale;
    scale.onUpdate = (ScaleUpdateDetails details) {
      updatedScale = details.scale;
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

    TestPointer pointer1 = new TestPointer(1);

    PointerDownEvent down = pointer1.down(const Point(10.0, 10.0));
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

    tester.route(pointer1.move(const Point(20.0, 30.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Point(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Two-finger scaling
    TestPointer pointer2 = new TestPointer(2);
    PointerDownEvent down2 = pointer2.down(const Point(10.0, 20.0));
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
    tester.route(pointer2.move(const Point(0.0, 10.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Point(10.0, 20.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Zoom out
    tester.route(pointer2.move(const Point(15.0, 25.0)));
    expect(updatedFocalPoint, const Point(17.5, 27.5));
    updatedFocalPoint = null;
    expect(updatedScale, 0.5);
    updatedScale = null;
    expect(didTap, isFalse);

    // Three-finger scaling
    TestPointer pointer3 = new TestPointer(3);
    PointerDownEvent down3 = pointer3.down(const Point(25.0, 35.0));
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
    tester.route(pointer3.move(const Point(55.0, 65.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Point(30.0, 40.0));
    updatedFocalPoint = null;
    expect(updatedScale, 5.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Return to original positions but with different fingers
    tester.route(pointer1.move(const Point(25.0, 35.0)));
    tester.route(pointer2.move(const Point(20.0, 30.0)));
    tester.route(pointer3.move(const Point(15.0, 25.0)));
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, const Point(20.0, 30.0));
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
    tester.route(pointer3.move(const Point(10.0, 20.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Point(15.0, 25.0));
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
    tester.route(pointer3.move(const Point(0.0, 0.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, const Point(0.0, 0.0));
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
}
