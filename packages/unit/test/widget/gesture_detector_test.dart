import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

void main() {
  test('Uncontested scrolls start immediately', () {
    WidgetTester tester = new WidgetTester();
    TestPointer pointer = new TestPointer(7);

    bool didStartScroll = false;
    double updatedScrollDelta;
    bool didEndScroll = false;

    Widget builder() {
      return new GestureDetector(
        onVerticalScrollStart: () {
          didStartScroll = true;
        },
        onVerticalScrollUpdate: (double scrollDelta) {
          updatedScrollDelta = scrollDelta;
        },
        onVerticalScrollEnd: () {
          didEndScroll = true;
        },
        child: new Container()
      );
    }

    tester.pumpFrame(builder);
    expect(didStartScroll, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndScroll, isFalse);

    Point firstLocation = new Point(10.0, 10.0);
    tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
    expect(didStartScroll, isTrue);
    didStartScroll = false;
    expect(updatedScrollDelta, isNull);
    expect(didEndScroll, isFalse);

    Point secondLocation = new Point(10.0, 9.0);
    tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
    expect(didStartScroll, isFalse);
    expect(updatedScrollDelta, 1.0);
    updatedScrollDelta = null;
    expect(didEndScroll, isFalse);

    tester.dispatchEvent(pointer.up(), firstLocation);
    expect(didStartScroll, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndScroll, isTrue);
    didEndScroll = false;

    tester.pumpFrame(() => new Container());
  });

  test('Match two scroll gestures in succession', () {
    WidgetTester tester = new WidgetTester();
    TestPointer pointer = new TestPointer(7);

    int gestureCount = 0;
    double dragDistance = 0.0;

    Point downLocation = new Point(10.0, 10.0);
    Point upLocation = new Point(10.0, 20.0);

    Widget builder() {
      return new GestureDetector(
        onVerticalScrollUpdate: (double delta) { dragDistance += delta; },
        onVerticalScrollEnd: () { gestureCount += 1; },
        onHorizontalScrollUpdate: (_) { fail("gesture should not match"); },
        onHorizontalScrollEnd: () { fail("gesture should not match"); },
        child: new Container()
      );
    }
    tester.pumpFrame(builder);

    tester.dispatchEvent(pointer.down(downLocation), downLocation);
    tester.dispatchEvent(pointer.move(upLocation), downLocation);
    tester.dispatchEvent(pointer.up(), downLocation);

    tester.dispatchEvent(pointer.down(downLocation), downLocation);
    tester.dispatchEvent(pointer.move(upLocation), downLocation);
    tester.dispatchEvent(pointer.up(), downLocation);

    expect(gestureCount, 2);
    expect(dragDistance, -20.0);
  });
}
