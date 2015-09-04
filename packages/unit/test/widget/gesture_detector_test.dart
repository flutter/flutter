import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

void main() {
  test('Uncontested scrolls start immediately', () {
    WidgetTester tester = new WidgetTester();
    TestPointer pointer = new TestPointer(7);

    bool didStartDrag = false;
    double updatedDragDelta;
    bool didEndDrag = false;

    Widget builder() {
      return new GestureDetector(
        onVerticalDragStart: () {
          didStartDrag = true;
        },
        onVerticalDragUpdate: (double scrollDelta) {
          updatedDragDelta = scrollDelta;
        },
        onVerticalDragEnd: () {
          didEndDrag = true;
        },
        child: new Container()
      );
    }

    tester.pumpFrame(builder);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    Point firstLocation = new Point(10.0, 10.0);
    tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    Point secondLocation = new Point(10.0, 9.0);
    tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, 1.0);
    updatedDragDelta = null;
    expect(didEndDrag, isFalse);

    tester.dispatchEvent(pointer.up(), firstLocation);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

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
        onVerticalDragUpdate: (double delta) { dragDistance += delta; },
        onVerticalDragEnd: () { gestureCount += 1; },
        onHorizontalDragUpdate: (_) { fail("gesture should not match"); },
        onHorizontalDragEnd: () { fail("gesture should not match"); },
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
