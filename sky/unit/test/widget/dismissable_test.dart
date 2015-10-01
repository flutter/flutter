import 'package:quiver/testing/async.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

const double itemExtent = 100.0;
ScrollDirection scrollDirection = ScrollDirection.vertical;
DismissDirection dismissDirection = DismissDirection.horizontal;
List<int> dismissedItems = [];

void handleOnResized(item) {
  expect(dismissedItems.contains(item), isFalse);
}

void handleOnDismissed(item) {
  expect(dismissedItems.contains(item), isFalse);
  dismissedItems.add(item);
}

Widget buildDismissableItem(BuildContext context, int item) {
  return new Dismissable(
    key: new ValueKey<int>(item),
    direction: dismissDirection,
    onDismissed: () { handleOnDismissed(item); },
    onResized: () { handleOnResized(item); },
    child: new Container(
      width: itemExtent,
      height: itemExtent,
      child: new Text(item.toString())
    )
  );
}

Widget widgetBuilder() {
  return new Container(
    padding: const EdgeDims.all(10.0),
    child: new ScrollableList<int>(
      items: [0, 1, 2, 3, 4].where((int i) => !dismissedItems.contains(i)).toList(),
      itemBuilder: buildDismissableItem,
      scrollDirection: scrollDirection,
      itemExtent: itemExtent
    )
  );
}

void dismissItem(WidgetTester tester, int item, { DismissDirection gestureDirection }) {
  assert(gestureDirection != DismissDirection.horizontal);
  assert(gestureDirection != DismissDirection.vertical);

  Element itemElement = tester.findText(item.toString());
  expect(itemElement, isNotNull);

  Point downLocation;
  Point upLocation;
  switch(gestureDirection) {
    case DismissDirection.left:
      // Note: getTopRight() returns a point that's just beyond
      // itemWidget's right edge and outside the Dismissable event
      // listener's bounds.
      downLocation = tester.getTopRight(itemElement) + const Offset(-0.1, 0.0);
      upLocation = tester.getTopLeft(itemElement);
      break;
    case DismissDirection.right:
      downLocation = tester.getTopLeft(itemElement);
      upLocation = tester.getTopRight(itemElement);
      break;
    case DismissDirection.up:
      // Note: getBottomLeft() returns a point that's just below
      // itemWidget's bottom edge and outside the Dismissable event
      // listener's bounds.
      downLocation = tester.getBottomLeft(itemElement) + const Offset(0.0, -0.1);
      upLocation = tester.getTopLeft(itemElement);
      break;
    case DismissDirection.down:
      downLocation = tester.getTopLeft(itemElement);
      upLocation = tester.getBottomLeft(itemElement);
      break;
    default:
      fail("unsupported gestureDirection");
  }

  TestPointer pointer = new TestPointer(5);
  tester.dispatchEvent(pointer.down(downLocation), downLocation);
  tester.dispatchEvent(pointer.move(upLocation), downLocation);
  tester.dispatchEvent(pointer.up(), downLocation);

  double t0 = 0.0;
  new FakeAsync().run((async) {
    tester.pumpFrame(widgetBuilder(), t0); // start the resize animation
    tester.pumpFrame(widgetBuilder(), t0 + 1000.0); // finish the resize animation
    async.elapse(new Duration(seconds: 1));
    tester.pumpFrame(widgetBuilder(), t0 + 2000.0); // dismiss
    async.elapse(new Duration(seconds: 1));
  });
}

void main() {
  test('Horizontal drag triggers dismiss scrollDirection=vertical', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.vertical;
    dismissDirection = DismissDirection.horizontal;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.right);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));

    dismissItem(tester, 1, gestureDirection: DismissDirection.left);
    expect(tester.findText('1'), isNull);
    expect(dismissedItems, equals([0, 1]));
  });

  test('Vertical drag triggers dismiss scrollDirection=horizontal', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.horizontal;
    dismissDirection = DismissDirection.vertical;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));

    dismissItem(tester, 1, gestureDirection: DismissDirection.down);
    expect(tester.findText('1'), isNull);
    expect(dismissedItems, equals([0, 1]));
  });

  test('drag-left with DismissDirection.left triggers dismiss', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.vertical;
    dismissDirection = DismissDirection.left;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.right);
    expect(tester.findText('0'), isNotNull);
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.left);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));
  });

  test('drag-right with DismissDirection.right triggers dismiss', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.vertical;
    dismissDirection = DismissDirection.right;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.left);
    expect(tester.findText('0'), isNotNull);
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.right);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));
  });

  test('drag-up with DismissDirection.up triggers dismiss', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.horizontal;
    dismissDirection = DismissDirection.up;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.down);
    expect(tester.findText('0'), isNotNull);
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));
  });

  test('drag-down with DismissDirection.down triggers dismiss', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.horizontal;
    dismissDirection = DismissDirection.down;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(tester.findText('0'), isNotNull);
    expect(dismissedItems, isEmpty);

    dismissItem(tester, 0, gestureDirection: DismissDirection.down);
    expect(tester.findText('0'), isNull);
    expect(dismissedItems, equals([0]));
  });

  // This is a regression test for
  // https://github.com/domokit/sky_engine/issues/1068
  test('Verify that drag-move events do not assert', () {
    WidgetTester tester = new WidgetTester();
    scrollDirection = ScrollDirection.horizontal;
    dismissDirection = DismissDirection.down;
    dismissedItems = [];

    tester.pumpFrame(widgetBuilder());
    Element itemElement = tester.findText('0');

    TestPointer pointer = new TestPointer(5);
    Point location = tester.getTopLeft(itemElement);
    Offset offset = new Offset(0.0, 5.0);
    tester.dispatchEvent(pointer.down(location), location);
    tester.dispatchEvent(pointer.move(location + offset), location);
    tester.pumpFrame(widgetBuilder());
    tester.dispatchEvent(pointer.move(location + (offset * 2.0)), location);
    tester.pumpFrame(widgetBuilder());
    tester.dispatchEvent(pointer.move(location + (offset * 3.0)), location);
    tester.pumpFrame(widgetBuilder());
    tester.dispatchEvent(pointer.move(location + (offset * 4.0)), location);
    tester.pumpFrame(widgetBuilder());
  });
}
