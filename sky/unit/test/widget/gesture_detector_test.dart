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
    tester.dispatchEvent(pointer.move(secondLocation), secondLocation);
    expect(didStartScroll, isFalse);
    expect(updatedScrollDelta, 1.0);
    updatedScrollDelta = null;
    expect(didEndScroll, isFalse);

    tester.dispatchEvent(pointer.up(), secondLocation);
    expect(didStartScroll, isFalse);
    expect(updatedScrollDelta, isNull);
    expect(didEndScroll, isTrue);
    didEndScroll = false;

    tester.pumpFrame(() => new Container());
  });
}
