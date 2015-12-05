import 'package:quiver/testing/async.dart';
import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

const PointerDownEvent down = const PointerDownEvent(
  pointer: 5,
  position: const Point(10.0, 10.0)
);

const PointerUpEvent up = const PointerUpEvent(
  pointer: 5,
  position: const Point(11.0, 9.0)
);

void main() {
  test('Should recognize long press', () {
    PointerRouter router = new PointerRouter();
    LongPressGestureRecognizer longPress = new LongPressGestureRecognizer(router: router);

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      longPress.addPointer(down);
      GestureArena.instance.close(5);
      expect(longPressRecognized, isFalse);
      router.route(down);
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(milliseconds: 300));
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(milliseconds: 700));
      expect(longPressRecognized, isTrue);
    });

    longPress.dispose();
  });

  test('Up cancels long press', () {
    PointerRouter router = new PointerRouter();
    LongPressGestureRecognizer longPress = new LongPressGestureRecognizer(router: router);

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      longPress.addPointer(down);
      GestureArena.instance.close(5);
      expect(longPressRecognized, isFalse);
      router.route(down);
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(milliseconds: 300));
      expect(longPressRecognized, isFalse);
      router.route(up);
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(longPressRecognized, isFalse);
    });

    longPress.dispose();
  });

  test('Should recognize both tap down and long press', () {
    PointerRouter router = new PointerRouter();
    TapGestureRecognizer tap = new TapGestureRecognizer(router: router);
    LongPressGestureRecognizer longPress = new LongPressGestureRecognizer(router: router);

    bool tapDownRecognized = false;
    tap.onTapDown = (_) {
      tapDownRecognized = true;
    };

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    new FakeAsync().run((FakeAsync async) {
      tap.addPointer(down);
      longPress.addPointer(down);
      GestureArena.instance.close(5);
      expect(tapDownRecognized, isFalse);
      expect(longPressRecognized, isFalse);
      router.route(down);
      expect(tapDownRecognized, isFalse);
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(milliseconds: 300));
      expect(tapDownRecognized, isTrue);
      expect(longPressRecognized, isFalse);
      async.elapse(const Duration(milliseconds: 700));
      expect(tapDownRecognized, isTrue);
      expect(longPressRecognized, isTrue);
    });

    tap.dispose();
    longPress.dispose();
  });
}
