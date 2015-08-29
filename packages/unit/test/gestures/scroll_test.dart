import 'dart:sky' as sky;

import 'package:sky/base/pointer_router.dart';
import 'package:sky/gestures/scroll.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';

TestPointerEvent down = new TestPointerEvent(
  pointer: 5,
  type: 'pointerdown',
  x: 10.0,
  y: 10.0
);

TestPointerEvent move1 = new TestPointerEvent(
  pointer: 5,
  type: 'pointermove',
  x: 20.0,
  y: 20.0,
  dx: 10.0,
  dy: 10.0
);

TestPointerEvent move2 = new TestPointerEvent(
  pointer: 5,
  type: 'pointermove',
  x: 20.0,
  y: 25.0,
  dx: 0.0,
  dy: 5.0
);

TestPointerEvent up = new TestPointerEvent(
  pointer: 5,
  type: 'pointerup',
  x: 20.0,
  y: 25.0
);

void main() {
  test('Should recognize scroll', () {
    PointerRouter router = new PointerRouter();
    PanGestureRecognizer scroll = new PanGestureRecognizer(router: router);

    bool didStartScroll = false;
    scroll.onStart = () {
      didStartScroll = true;
    };

    sky.Offset updateOffset;
    scroll.onUpdate = (sky.Offset offset) {
      updateOffset = offset;
    };

    bool didEndScroll = false;
    scroll.onEnd = () {
      didEndScroll = true;
    };

    scroll.addPointer(down);
    expect(didStartScroll, isFalse);
    expect(updateOffset, isNull);
    expect(didEndScroll, isFalse);

    router.handleEvent(down, null);
    expect(didStartScroll, isFalse);
    expect(updateOffset, isNull);
    expect(didEndScroll, isFalse);

    router.handleEvent(move1, null);
    expect(didStartScroll, isTrue);
    didStartScroll = false;
    expect(updateOffset, new sky.Offset(10.0, -10.0));
    updateOffset = null;
    expect(didEndScroll, isFalse);

    router.handleEvent(move2, null);
    expect(didStartScroll, isFalse);
    expect(updateOffset, new sky.Offset(0.0, -5.0));
    updateOffset = null;
    expect(didEndScroll, isFalse);

    router.handleEvent(up, null);
    expect(didStartScroll, isFalse);
    expect(updateOffset, isNull);
    expect(didEndScroll, isTrue);
    didEndScroll = false;

    scroll.dispose();
  });
}
