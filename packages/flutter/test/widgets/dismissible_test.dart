// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const double itemExtent = 100.0;
const Axis defaultScrollDirection = Axis.vertical;
Axis scrollDirection = defaultScrollDirection;
const DismissDirection defaultDismissDirection = DismissDirection.horizontal;
DismissDirection dismissDirection = defaultDismissDirection;
late DismissDirection reportedDismissDirection;
List<int> dismissedItems = <int>[];
Widget? background;
const double crossAxisEndOffset = 0.5;

Widget buildTest({
  double? startToEndThreshold,
  TextDirection textDirection = TextDirection.ltr,
  Future<bool?> Function(BuildContext context, DismissDirection direction)? confirmDismiss,
  ScrollController? controller,
}) {
  return Directionality(
    textDirection: textDirection,
    child: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        Widget buildDismissibleItem(int item) {
          return Dismissible(
            dragStartBehavior: DragStartBehavior.down,
            key: ValueKey<int>(item),
            direction: dismissDirection,
            confirmDismiss: confirmDismiss == null ? null : (DismissDirection direction) {
              return confirmDismiss(context, direction);
            },
            onDismissed: (DismissDirection direction) {
              setState(() {
                reportedDismissDirection = direction;
                expect(dismissedItems.contains(item), isFalse);
                dismissedItems.add(item);
              });
            },
            onResize: () {
              expect(dismissedItems.contains(item), isFalse);
            },
            background: background,
            dismissThresholds: startToEndThreshold == null
                ? <DismissDirection, double>{}
                : <DismissDirection, double>{DismissDirection.startToEnd: startToEndThreshold},
            crossAxisEndOffset: crossAxisEndOffset,
            child: SizedBox(
              width: itemExtent,
              height: itemExtent,
              child: Text(item.toString()),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            controller: controller,
            dragStartBehavior: DragStartBehavior.down,
            scrollDirection: scrollDirection,
            itemExtent: itemExtent,
            children: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8]
              .where((int i) => !dismissedItems.contains(i))
              .map<Widget>(buildDismissibleItem).toList(),
          ),
        );
      },
    ),
  );
}

typedef DismissMethod = Future<void> Function(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection });

Future<void> dismissElement(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection }) async {
  Offset downLocation;
  Offset upLocation;
  switch (gestureDirection) {
    case AxisDirection.left:
      // getTopRight() returns a point that's just beyond itemWidget's right
      // edge and outside the Dismissible event listener's bounds.
      downLocation = tester.getTopRight(finder) + const Offset(-0.1, 0.0);
      upLocation = tester.getTopLeft(finder);
      break;
    case AxisDirection.right:
      // we do the same thing here to keep the test symmetric
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getTopRight(finder);
      break;
    case AxisDirection.up:
      // getBottomLeft() returns a point that's just below itemWidget's bottom
      // edge and outside the Dismissible event listener's bounds.
      downLocation = tester.getBottomLeft(finder) + const Offset(0.0, -0.1);
      upLocation = tester.getTopLeft(finder);
      break;
    case AxisDirection.down:
      // again with doing the same here for symmetry
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getBottomLeft(finder);
      break;
  }

  final TestGesture gesture = await tester.startGesture(downLocation);
  await gesture.moveTo(upLocation);
  await gesture.up();
}

Future<void> flingElement(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection, double initialOffsetFactor = 0.0 }) async {
  Offset delta;
  switch (gestureDirection) {
    case AxisDirection.left:
      delta = const Offset(-300.0, 0.0);
      break;
    case AxisDirection.right:
      delta = const Offset(300.0, 0.0);
      break;
    case AxisDirection.up:
      delta = const Offset(0.0, -300.0);
      break;
    case AxisDirection.down:
      delta = const Offset(0.0, 300.0);
      break;
  }
  await tester.fling(finder, delta, 1000.0, initialOffset: delta * initialOffsetFactor);
}

Future<void> flingElementFromZero(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection }) async {
  // This is a special case where we drag in one direction, then fling back so
  // that at the point of release, we're at exactly the point at which we
  // started, but with velocity. This is needed to check a boundary condition
  // in the flinging behavior.
  await flingElement(tester, finder, gestureDirection: gestureDirection, initialOffsetFactor: -1.0);
}

Future<void> dismissItem(
  WidgetTester tester,
  int item, {
  required AxisDirection gestureDirection,
  DismissMethod mechanism = dismissElement,
}) async {
  assert(gestureDirection != null);
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pump(); // start the slide
  await tester.pump(const Duration(seconds: 1)); // finish the slide and start shrinking...
  await tester.pump(); // first frame of shrinking animation
  await tester.pump(const Duration(seconds: 1)); // finish the shrinking and call the callback...
  await tester.pump(); // rebuild after the callback removes the entry
}

Future<void> checkFlingItemBeforeMovementEnd(
  WidgetTester tester,
  int item, {
  required AxisDirection gestureDirection,
  DismissMethod mechanism = rollbackElement,
}) async {
  assert(gestureDirection != null);
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pump(); // start the slide
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> checkFlingItemAfterMovement(
  WidgetTester tester,
  int item, {
  required AxisDirection gestureDirection,
  DismissMethod mechanism = rollbackElement,
}) async {
  assert(gestureDirection != null);
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pump(); // start the slide
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> rollbackElement(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection, double initialOffsetFactor = 0.0 }) async {
  Offset delta;
  switch (gestureDirection) {
    case AxisDirection.left:
      delta = const Offset(-30.0, 0.0);
      break;
    case AxisDirection.right:
      delta = const Offset(30.0, 0.0);
      break;
    case AxisDirection.up:
      delta = const Offset(0.0, -30.0);
      break;
    case AxisDirection.down:
      delta = const Offset(0.0, 30.0);
      break;
  }
  await tester.fling(finder, delta, 1000.0, initialOffset: delta * initialOffsetFactor);
}

class Test1215DismissibleWidget extends StatelessWidget {
  const Test1215DismissibleWidget(this.text, { Key? key }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      dragStartBehavior: DragStartBehavior.down,
      key: ObjectKey(text),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Text(text),
      ),
    );
  }
}

void main() {
  setUp(() {
    dismissedItems = <int>[];
    background = null;
  });

  tearDown(() {
    // Restore the default values of dismissDirection and scrollDirection
    // in order to ensure consistency when the test order is randomized.
    dismissDirection = defaultDismissDirection;
    scrollDirection = defaultScrollDirection;
  });

  testWidgets('Horizontal drag triggers dismiss scrollDirection=vertical', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.endToStart);
  });

  testWidgets('Horizontal fling triggers dismiss scrollDirection=vertical', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.endToStart);
  });

  testWidgets('Horizontal fling does not trigger at zero offset, but does otherwise', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(buildTest(startToEndThreshold: 0.95));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElementFromZero);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, equals(<int>[]));

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left, mechanism: flingElementFromZero);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, equals(<int>[]));

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.endToStart);
  });

  testWidgets('Vertical drag triggers dismiss scrollDirection=horizontal', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.vertical;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.up);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.down);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.down);
  });

  testWidgets('drag-left with DismissDirection.endToStart triggers dismiss (LTR)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.endToStart;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, gestureDirection: AxisDirection.right);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    await dismissItem(tester, 1, gestureDirection: AxisDirection.left);
  });

  testWidgets('drag-right with DismissDirection.startToEnd triggers dismiss (LTR)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.startToEnd;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-right with DismissDirection.endToStart triggers dismiss (RTL)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.endToStart;

    await tester.pumpWidget(buildTest(textDirection: TextDirection.rtl));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-left with DismissDirection.startToEnd triggers dismiss (RTL)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.startToEnd;

    await tester.pumpWidget(buildTest(textDirection: TextDirection.rtl));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, gestureDirection: AxisDirection.right);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    await dismissItem(tester, 1, gestureDirection: AxisDirection.left);
  });

  testWidgets('fling-left with DismissDirection.endToStart triggers dismiss (LTR)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.endToStart;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, gestureDirection: AxisDirection.right);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    await dismissItem(tester, 1, gestureDirection: AxisDirection.left);
  });

  testWidgets('fling-right with DismissDirection.startToEnd triggers dismiss (LTR)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.startToEnd;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-right with DismissDirection.endToStart triggers dismiss (RTL)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.endToStart;

    await tester.pumpWidget(buildTest(textDirection: TextDirection.rtl));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-left with DismissDirection.startToEnd triggers dismiss (RTL)', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.startToEnd;

    await tester.pumpWidget(buildTest(textDirection: TextDirection.rtl));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, mechanism: flingElement, gestureDirection: AxisDirection.right);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    await dismissItem(tester, 1, mechanism: flingElement, gestureDirection: AxisDirection.left);
  });

  testWidgets('drag-up with DismissDirection.up triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.up;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-down with DismissDirection.down triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.down;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-up with DismissDirection.up triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.up;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-down with DismissDirection.down triggers dismiss', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    dismissDirection = DismissDirection.down;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-left has no effect on dismissible with a high dismiss threshold', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(buildTest(startToEndThreshold: 1.0));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-left has no effect on dismissible with a high dismiss threshold', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(buildTest(startToEndThreshold: 1.0));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
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

    await tester.pumpWidget(buildTest());
    final Offset location = tester.getTopLeft(find.text('0'));
    const Offset offset = Offset(0.0, 5.0);
    final TestGesture gesture = await tester.startGesture(location, pointer: 5);
    await gesture.moveBy(offset);
    await tester.pumpWidget(buildTest());
    await gesture.moveBy(offset);
    await tester.pumpWidget(buildTest());
    await gesture.moveBy(offset);
    await tester.pumpWidget(buildTest());
    await gesture.moveBy(offset);
    await tester.pumpWidget(buildTest());
    await gesture.up();
  });

  // This one is for a case where dismissing a widget above a previously
  // dismissed widget threw an exception, which was documented at the
  // now-obsolete URL https://github.com/flutter/engine/issues/1215 (the URL
  // died in the migration to the new repo). Don't copy this test; it doesn't
  // actually remove the dismissed widget, which is a violation of the
  // Dismissible contract. This is not an example of good practice.
  testWidgets('dismissing bottom then top (smoketest)', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 1000.0,
            child: Column(
              children: const <Widget>[
                Test1215DismissibleWidget('1'),
                Test1215DismissibleWidget('2'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await dismissElement(tester, find.text('2'), gestureDirection: AxisDirection.right);
    await tester.pump(); // start the slide away
    await tester.pump(const Duration(seconds: 1)); // finish the slide away
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await dismissElement(tester, find.text('1'), gestureDirection: AxisDirection.right);
    await tester.pump(); // start the slide away
    await tester.pump(const Duration(seconds: 1)); // finish the slide away (at which point the child is no longer included in the tree)
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('Dismissible starts from the full size when collapsing', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;
    background = const Text('background');

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    final Finder itemFinder = find.text('0');
    expect(itemFinder, findsOneWidget);
    await dismissElement(tester, itemFinder, gestureDirection: AxisDirection.right);
    await tester.pump();

    expect(find.text('background'), findsOneWidget); // The other four have been culled.
    final RenderBox backgroundBox = tester.firstRenderObject(find.text('background'));
    expect(backgroundBox.size.height, equals(100.0));
  });

  testWidgets('Checking fling item before movementDuration completes', (WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemBeforeMovementEnd(tester, 0, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);

    await checkFlingItemBeforeMovementEnd(tester, 1, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Checking fling item after movementDuration', (WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsNothing);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Horizontal fling less than threshold', (WidgetTester tester) async {
    scrollDirection = Axis.horizontal;
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.left, mechanism: rollbackElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.right, mechanism: rollbackElement);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
  });

  testWidgets('Vertical fling less than threshold', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.left, mechanism: rollbackElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.right, mechanism: rollbackElement);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
  });

  testWidgets('confirmDismiss returns values: true, false, null', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;
    late DismissDirection confirmDismissDirection;

    Widget buildFrame(bool? confirmDismissValue) {
      return buildTest(
        confirmDismiss: (BuildContext context, DismissDirection dismissDirection) {
          confirmDismissDirection = dismissDirection;
          return Future<bool?>.value(confirmDismissValue);
        },
      );
    }

    // Dismiss is confirmed IFF confirmDismiss() returns true.
    await tester.pumpWidget(buildFrame(true));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissDirection, DismissDirection.startToEnd);
    expect(confirmDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissDirection, DismissDirection.endToStart);
    expect(confirmDismissDirection, DismissDirection.endToStart);

    // Dismiss is not confirmed if confirmDismiss() returns false
    dismissedItems = <int>[];
    await tester.pumpWidget(buildFrame(false));

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    expect(confirmDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    expect(confirmDismissDirection, DismissDirection.endToStart);

    // Dismiss is not confirmed if confirmDismiss() returns null
    dismissedItems = <int>[];
    await tester.pumpWidget(buildFrame(null));

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    expect(confirmDismissDirection, DismissDirection.startToEnd);

    await dismissItem(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
    expect(confirmDismissDirection, DismissDirection.endToStart);
  });

  testWidgets('setState that does not remove the Dismissible from tree should throws Error', (WidgetTester tester) async {
    scrollDirection = Axis.vertical;
    dismissDirection = DismissDirection.horizontal;

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ListView(
            dragStartBehavior: DragStartBehavior.down,
            scrollDirection: scrollDirection,
            itemExtent: itemExtent,
            children: <Widget>[
              Dismissible(
                dragStartBehavior: DragStartBehavior.down,
                key: const ValueKey<int>(1),
                direction: dismissDirection,
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    reportedDismissDirection = direction;
                    expect(dismissedItems.contains(1), isFalse);
                    dismissedItems.add(1);
                  });
                },
                background: background,
                dismissThresholds: const <DismissDirection, double>{},
                crossAxisEndOffset: crossAxisEndOffset,
                child: SizedBox(
                  width: itemExtent,
                  height: itemExtent,
                  child: Text(1.toString()),
                ),
              ),
            ],
          );
        },
      ),
    ));
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 1, gestureDirection: AxisDirection.right);
    expect(dismissedItems, equals(<int>[1]));
    final dynamic exception =  tester.takeException();
    expect(exception, isNotNull);
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.last.level, DiagnosticLevel.hint);
    expect(
      error.diagnostics.last.toStringDeep(),
      equalsIgnoringHashCodes(
        'Make sure to implement the onDismissed handler and to immediately\n'
        'remove the Dismissible widget from the application once that\n'
        'handler has fired.\n',
      ),
    );
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   A dismissed Dismissible widget is still part of the tree.\n'
      '   Make sure to implement the onDismissed handler and to immediately\n'
      '   remove the Dismissible widget from the application once that\n'
      '   handler has fired.\n',
    );
  });

  testWidgets('Dismissible.behavior should behave correctly during hit testing', (WidgetTester tester) async {
    bool didReceivePointerDown = false;

    Widget buildStack({required Widget child}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Listener(
              onPointerDown: (_) {
                didReceivePointerDown = true;
              },
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF00FF00),
              ),
            ),
            child,
          ],
        ),
      );
    }

    await tester.pumpWidget(
      buildStack(
        child: const Dismissible(
          key: ValueKey<int>(1),
          child: SizedBox(
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isFalse);

    Future<void> pumpWidgetTree(HitTestBehavior behavior) {
      return tester.pumpWidget(
        buildStack(
          child: Dismissible(
            key: const ValueKey<int>(1),
            behavior: behavior,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );
    }

    didReceivePointerDown = false;
    await pumpWidgetTree(HitTestBehavior.deferToChild);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isTrue);

    didReceivePointerDown = false;
    await pumpWidgetTree(HitTestBehavior.opaque);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isFalse);

    didReceivePointerDown = false;
    await pumpWidgetTree(HitTestBehavior.translucent);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isTrue);
  });

  testWidgets('DismissDirection.none does not trigger dismiss', (WidgetTester tester) async {
    dismissDirection = DismissDirection.none;

    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('DismissDirection.none does not prevent scrolling', (WidgetTester tester) async {
    dismissDirection = DismissDirection.none;
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(buildTest(controller: controller));
    expect(dismissedItems, isEmpty);
    expect(controller.offset, 0.0);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(controller.offset, 99.9);
  });
}
