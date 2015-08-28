import 'package:quiver/testing/async.dart';
import 'package:sky/base/pointer_router.dart';
import 'package:sky/gestures/long_press.dart';
import 'package:sky/gestures/show_press.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';

final TestPointerEvent down = new TestPointerEvent(
  pointer: 5,
  type: 'pointerdown',
  x: 10.0,
  y: 10.0
);

final TestPointerEvent up = new TestPointerEvent(
  pointer: 5,
  type: 'pointerup',
  x: 11.0,
  y: 9.0
);

void main() {
  test('Should recognize long press', () {
    PointerRouter router = new PointerRouter();
    LongPressGestureRecognizer longPress = new LongPressGestureRecognizer(router: router);

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    new FakeAsync().run((async) {
      longPress.addPointer(down);
      expect(longPressRecognized, isFalse);
      router.handleEvent(down, null);
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(milliseconds: 300));
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(milliseconds: 700));
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

    new FakeAsync().run((async) {
      longPress.addPointer(down);
      expect(longPressRecognized, isFalse);
      router.handleEvent(down, null);
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(milliseconds: 300));
      expect(longPressRecognized, isFalse);
      router.handleEvent(up, null);
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(seconds: 1));
      expect(longPressRecognized, isFalse);
    });

    longPress.dispose();
  });

  test('Should recognize both show press and long press', () {
    PointerRouter router = new PointerRouter();
    ShowPressGestureRecognizer showPress = new ShowPressGestureRecognizer(router: router);
    LongPressGestureRecognizer longPress = new LongPressGestureRecognizer(router: router);

    bool showPressRecognized = false;
    showPress.onShowPress = () {
      showPressRecognized = true;
    };

    bool longPressRecognized = false;
    longPress.onLongPress = () {
      longPressRecognized = true;
    };

    new FakeAsync().run((async) {
      showPress.addPointer(down);
      longPress.addPointer(down);
      expect(showPressRecognized, isFalse);
      expect(longPressRecognized, isFalse);
      router.handleEvent(down, null);
      expect(showPressRecognized, isFalse);
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(milliseconds: 300));
      expect(showPressRecognized, isTrue);
      expect(longPressRecognized, isFalse);
      async.elapse(new Duration(milliseconds: 700));
      expect(showPressRecognized, isTrue);
      expect(longPressRecognized, isTrue);
    });

    showPress.dispose();
    longPress.dispose();
  });
}
