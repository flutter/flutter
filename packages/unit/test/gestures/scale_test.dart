import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

void main() {
  test('Should recognize scale gestures', () {
    PointerRouter router = new PointerRouter();
    ScaleGestureRecognizer scale = new ScaleGestureRecognizer(router: router);
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool didStartScale = false;
    ui.Point updatedFocalPoint;
    scale.onStart = (ui.Point focalPoint) {
      didStartScale = true;
      updatedFocalPoint = focalPoint;
    };

    double updatedScale;
    scale.onUpdate = (double scale, ui.Point focalPoint) {
      updatedScale = scale;
      updatedFocalPoint = focalPoint;
    };

    bool didEndScale = false;
    scale.onEnd = () {
      didEndScale = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    TestPointer pointer1 = new TestPointer(1);

    PointerInputEvent down = pointer1.down(new Point(10.0, 10.0));
    scale.addPointer(down);
    tap.addPointer(down);

    GestureArena.instance.close(1);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // One-finger panning
    router.route(down);
    expect(didStartScale, isFalse);
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    router.route(pointer1.move(new Point(20.0, 30.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, new ui.Point(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Two-finger scaling
    TestPointer pointer2 = new TestPointer(2);
    PointerInputEvent down2 = pointer2.down(new Point(10.0, 20.0));
    scale.addPointer(down2);
    tap.addPointer(down2);
    GestureArena.instance.close(2);
    router.route(down2);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    router.route(pointer2.move(new Point(0.0, 10.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, new ui.Point(10.0, 20.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Zoom out
    router.route(pointer2.move(new Point(15.0, 25.0)));
    expect(updatedFocalPoint, new ui.Point(17.5, 27.5));
    updatedFocalPoint = null;
    expect(updatedScale, 0.5);
    updatedScale = null;
    expect(didTap, isFalse);

    // Three-finger scaling
    TestPointer pointer3 = new TestPointer(3);
    PointerInputEvent down3 = pointer3.down(new Point(25.0, 35.0));
    scale.addPointer(down3);
    tap.addPointer(down3);
    GestureArena.instance.close(3);
    router.route(down3);

    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(updatedScale, isNull);
    expect(updatedFocalPoint, isNull);
    expect(didStartScale, isFalse);

    // Zoom in
    router.route(pointer3.move(new Point(55.0, 65.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, new ui.Point(30.0, 40.0));
    updatedFocalPoint = null;
    expect(updatedScale, 5.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    // Return to original positions but with different fingers
    router.route(pointer1.move(new Point(25.0, 35.0)));
    router.route(pointer2.move(new Point(20.0, 30.0)));
    router.route(pointer3.move(new Point(15.0, 25.0)));
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, new ui.Point(20.0, 30.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;
    expect(didEndScale, isFalse);
    expect(didTap, isFalse);

    router.route(pointer1.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue scaling with two fingers
    router.route(pointer3.move(new Point(10.0, 20.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, new ui.Point(15.0, 25.0));
    updatedFocalPoint = null;
    expect(updatedScale, 2.0);
    updatedScale = null;

    router.route(pointer2.up());
    expect(didStartScale, isFalse);
    expect(updatedFocalPoint, isNull);
    expect(updatedScale, isNull);
    expect(didEndScale, isTrue);
    didEndScale = false;
    expect(didTap, isFalse);

    // Continue panning with one finger
    router.route(pointer3.move(new Point(0.0, 0.0)));
    expect(didStartScale, isTrue);
    didStartScale = false;
    expect(updatedFocalPoint, new ui.Point(0.0, 0.0));
    updatedFocalPoint = null;
    expect(updatedScale, 1.0);
    updatedScale = null;

    // We are done
    router.route(pointer3.up());
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
