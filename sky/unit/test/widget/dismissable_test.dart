import 'package:quiver/testing/async.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

void main() {
  test('Horizontal drag triggers dismiss', () {
    WidgetTester tester = new WidgetTester();
    TestPointer pointer = new TestPointer(5);

    const double itemHeight = 50.0;
    List<int> dismissedItems = [];

    void handleOnResized(item) {
      expect(dismissedItems.contains(item), isFalse);
    }

    void handleOnDismissed(item) {
      expect(dismissedItems.contains(item), isFalse);
      dismissedItems.add(item);
    }

    Widget buildDismissableItem(int item) {
      return new Dismissable(
        key: new ValueKey<int>(item),
        onDismissed: () { handleOnDismissed(item); },
        onResized: () { handleOnResized(item); },
        child: new Container(
          height: itemHeight,
          child: new Text(item.toString())
        )
      );
    }

    Widget builder() {
      return new Container(
        padding: const EdgeDims.all(10.0),
        child: new ScrollableList<int>(
          items: [0, 1, 2, 3, 4, 5],
          itemBuilder: buildDismissableItem,
          scrollDirection: ScrollDirection.vertical,
          itemExtent: itemHeight
        )
      );
    }

    tester.pumpFrame(builder);
    Widget item3 = tester.findText("3");
    expect(item3, isNotNull);
    expect(dismissedItems, isEmpty);

    // Gesture: press-drag-release from the Dismissable's top-left corner
    // to its top-right corner. Triggers the resize animation which concludes
    // by calling onDismissed().
    Point downLocation = tester.getTopLeft(item3);
    Point upLocation = tester.getTopRight(item3);
    tester.dispatchEvent(pointer.down(downLocation), downLocation);
    tester.dispatchEvent(pointer.move(upLocation), upLocation);
    tester.dispatchEvent(pointer.up(), upLocation);

    new FakeAsync().run((async) {
      tester.pumpFrame(builder); // start the resize animation
      tester.pumpFrame(builder, 1000.0); // finish the resize animation
      async.elapse(new Duration(seconds: 1));
      tester.pumpFrame(builder, 2000.0); // dismiss
      async.elapse(new Duration(seconds: 1));
      expect(dismissedItems, equals([3]));
      expect(tester.findText("3"), isNull);
    });

  });
}
