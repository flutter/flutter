import 'dart:sky' as sky;

import 'package:sky/base/pointer_router.dart';
import 'package:sky/gestures/arena.dart';
import 'package:sky/gestures/scroll.dart';
import 'package:sky/gestures/tap.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';

void main() {
  test('Should recognize pan', () {
    PointerRouter router = new PointerRouter();
    PanGestureRecognizer pan = new PanGestureRecognizer(router: router);
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool didStartPan = false;
    pan.onStart = () {
      didStartPan = true;
    };

    sky.Offset updatedScrollDelta;
    pan.onUpdate = (sky.Offset offset) {
      updatedScrollDelta = offset;
    };

    bool didEndPan = false;
    pan.onEnd = () {
      didEndPan = true;
    };

    bool didTap = false;
    tap.onTap = () {
      didTap = true;
    };

    TestPointer pointer = new TestPointer(5);
    sky.PointerEvent down = pointer.down(new Point(10.0, 10.0));
    pan.addPointer(down);
    tap.addPointer(down);
    GestureArena.instance.close(5);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(down);
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(new Point(20.0, 20.0)));
    expect(didStartPan, isTrue);
    didStartPan = false;
    expect(updatedScrollDelta, new sky.Offset(10.0, -10.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.move(new Point(20.0, 25.0)));
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, new sky.Offset(0.0, -5.0));
    updatedScrollDelta = null;
    expect(didEndPan, isFalse);
    expect(didTap, isFalse);

    router.route(pointer.up());
    expect(didStartPan, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndPan, isTrue);
    didEndPan = false;
    expect(didTap, isFalse);

    pan.dispose();
    tap.dispose();
  });
}
