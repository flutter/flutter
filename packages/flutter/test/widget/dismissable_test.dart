// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const double itemExtent = 100.0;
Axis scrollDirection = Axis.vertical;
DismissDirection dismissDirection = DismissDirection.horizontal;
DismissDirection reportedDismissDirection;
List<int> dismissedItems = <int>[];
Widget background;

void handleOnResize(int item) {
  expect(dismissedItems.contains(item), isFalse);
}

void handleOnDismissed(DismissDirection direction, int item) {
  reportedDismissDirection = direction;
  expect(dismissedItems.contains(item), isFalse);
  dismissedItems.add(item);
}

Widget buildDismissableItem(int item) {
  return new Dismissable(
    key: new ValueKey<int>(item),
    direction: dismissDirection,
    onDismissed: (DismissDirection direction) { handleOnDismissed(direction, item); },
    onResize: () { handleOnResize(item); },
    background: background,
    child: new Container(
      width: itemExtent,
      height: itemExtent,
      child: new Text(item.toString())
    )
  );
}

Widget widgetBuilder() {
  return new Container(
    padding: const EdgeInsets.all(10.0),
    child: new ScrollableList(
      scrollDirection: scrollDirection,
      itemExtent: itemExtent,
      children: <int>[0, 1, 2, 3, 4].where(
        (int i) => !dismissedItems.contains(i)
      ).map(buildDismissableItem)
    )
  );
}

Future<Null> dismissElement(WidgetTester tester, Finder finder, { DismissDirection gestureDirection }) async {
  assert(tester.any(finder));
  assert(gestureDirection != DismissDirection.horizontal);
  assert(gestureDirection != DismissDirection.vertical);

  Point downLocation;
  Point upLocation;
  switch(gestureDirection) {
    case DismissDirection.endToStart:
      // getTopRight() returns a point that's just beyond itemWidget's right
      // edge and outside the Dismissable event listener's bounds.
      downLocation = tester.getTopRight(finder) + const Offset(-0.1, 0.0);
      upLocation = tester.getTopLeft(finder);
      break;
    case DismissDirection.startToEnd:
      // we do the same thing here to keep the test symmetric
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getTopRight(finder);
      break;
    case DismissDirection.up:
      // getBottomLeft() returns a point that's just below itemWidget's bottom
      // edge and outside the Dismissable event listener's bounds.
      downLocation = tester.getBottomLeft(finder) + const Offset(0.0, -0.1);
      upLocation = tester.getTopLeft(finder);
      break;
    case DismissDirection.down:
      // again with doing the same here for symmetry
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getBottomLeft(finder);
      break;
    default:
      fail("unsupported gestureDirection");
  }

  TestGesture gesture = await tester.startGesture(downLocation, pointer: 5);
  await gesture.moveTo(upLocation);
  await gesture.up();
}

Future<Null> dismissItem(WidgetTester tester, int item, { DismissDirection gestureDirection }) async {
  assert(gestureDirection != DismissDirection.horizontal);
  assert(gestureDirection != DismissDirection.vertical);

  Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await dismissElement(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pumpWidget(widgetBuilder()); // start the slide
  await tester.pumpWidget(widgetBuilder(), const Duration(seconds: 1)); // finish the slide and start shrinking...
  await tester.pumpWidget(widgetBuilder()); // first frame of shrinking animation
  await tester.pumpWidget(widgetBuilder(), const Duration(seconds: 1)); // finish the shrinking and call the callback...
  await tester.pumpWidget(widgetBuilder()); // rebuild after the callback removes the entry
}

class Test1215DismissableWidget extends StatelessWidget {
  Test1215DismissableWidget(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return new Dismissable(
      key: new ObjectKey(text),
      child: new AspectRatio(
        aspectRatio: 1.0,
        child: new Text(this.text)
      )
    );
  }
}

void main() {
  setUp(() {
    dismissedItems = <int>[];
    background = null;
  });

  testWidgets('Horizontal drag triggers dismiss scrollDirection=vertical', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.startToEnd);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: DismissDirection.endToStart);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.endToStart);
  });

  testWidgets('Vertical drag triggers dismiss scrollDirection=horizontal', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.vertical;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.up);

    await dismissItem(tester, 1, gestureDirection: DismissDirection.down);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.down);
  });

  testWidgets('drag-left with DismissDirection.left triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.endToStart;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.startToEnd);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, gestureDirection: DismissDirection.startToEnd);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.endToStart);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    await dismissItem(tester, 1, gestureDirection: DismissDirection.endToStart);
  });

  testWidgets('drag-right with DismissDirection.right triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.startToEnd;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.endToStart);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.startToEnd);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-up with DismissDirection.up triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.up;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.down);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-down with DismissDirection.down triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.down;

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.up);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: DismissDirection.down);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  // This is a regression test for an fn2 bug where dragging a card caused an
  // assert "'!_disqualifiedFromEverAppearingAgain' is not true". The old URL
  // was https://github.com/domokit/sky_engine/issues/1068 but that issue is 404
  // now since we migrated to the new repo. The bug was fixed by
  // https://github.com/flutter/engine/pull/1134 at the time, and later made
  // irrelevant by fn3, but just in case...
  testWidgets('Verify that drag-move events do not assert', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.down;

    await tester.pumpWidget(widgetBuilder());
    Point location = tester.getTopLeft(find.text('0'));
    Offset offset = new Offset(0.0, 5.0);
    TestGesture gesture = await tester.startGesture(location, pointer: 5);
    await gesture.moveBy(offset);
    await tester.pumpWidget(widgetBuilder());
    await gesture.moveBy(offset);
    await tester.pumpWidget(widgetBuilder());
    await gesture.moveBy(offset);
    await tester.pumpWidget(widgetBuilder());
    await gesture.moveBy(offset);
    await tester.pumpWidget(widgetBuilder());
    await gesture.up();
  });

  // This one is for a case where dssmissing a widget above a previously
  // dismissed widget threw an exception, which was documented at the
  // now-obsolete URL https://github.com/flutter/engine/issues/1215 (the URL
  // died in the migration to the new repo). Don't copy this test; it doesn't
  // actually remove the dismissed widget, which is a violation of the
  // Dismissable contract. This is not an example of good practice.
  testWidgets('dismissing bottom then top (smoketest)', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(
      child: new Container(
        width: 100.0,
        height: 1000.0,
        child: new Column(
          children: <Widget>[
            new Test1215DismissableWidget('1'),
            new Test1215DismissableWidget('2')
          ]
        )
      )
    ));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await dismissElement(tester, find.text('2'), gestureDirection: DismissDirection.startToEnd);
    await tester.pump(); // start the slide away
    await tester.pump(new Duration(seconds: 1)); // finish the slide away
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await dismissElement(tester, find.text('1'), gestureDirection: DismissDirection.startToEnd);
    await tester.pump(); // start the slide away
    await tester.pump(new Duration(seconds: 1)); // finish the slide away (at which point the child is no longer included in the tree)
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('Dismissable starts from the full size when collapsing', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;
    background = new Text('background');

    await tester.pumpWidget(widgetBuilder());
    expect(dismissedItems, isEmpty);

    Finder itemFinder = find.text('0');
    expect(itemFinder, findsOneWidget);
    await dismissElement(tester, itemFinder, gestureDirection: DismissDirection.startToEnd);
    await tester.pump();

    expect(find.text('background'), findsOneWidget); // The other four have been culled.
    RenderBox backgroundBox = tester.firstRenderObject(find.text('background'));
    expect(backgroundBox.size.height, equals(100.0));
  });
}
