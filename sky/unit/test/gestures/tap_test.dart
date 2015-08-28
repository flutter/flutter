import 'package:sky/base/pointer_router.dart';
import 'package:sky/gestures/tap.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';

void main() {
  test('Should recognize tap', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    TestPointerEvent down = new TestPointerEvent(
      pointer: 5,
      type: 'pointerdown',
      x: 10.0,
      y: 10.0
    );

    tap.addPointer(down);
    expect(tapRecognized, isFalse);
    router.handleEvent(down, null);
    expect(tapRecognized, isFalse);

    TestPointerEvent up = new TestPointerEvent(
      pointer: 5,
      type: 'pointerup',
      x: 11.0,
      y: 9.0
    );

    router.handleEvent(up, null);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });
}
