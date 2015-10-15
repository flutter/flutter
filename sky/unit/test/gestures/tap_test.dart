import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

void main() {
  test('Should recognize tap', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    PointerInputEvent down = new PointerInputEvent(
      pointer: 5,
      type: 'pointerdown',
      x: 10.0,
      y: 10.0
    );

    tap.addPointer(down);
    GestureArena.instance.close(5);
    expect(tapRecognized, isFalse);
    router.route(down);
    expect(tapRecognized, isFalse);

    PointerInputEvent up = new PointerInputEvent(
      pointer: 5,
      type: 'pointerup',
      x: 11.0,
      y: 9.0
    );

    router.route(up);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });
}
