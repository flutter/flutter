// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const DismissDirection defaultDismissDirection = DismissDirection.horizontal;
const double crossAxisEndOffset = 0.5;
bool reportedDismissUpdateReached = false;
bool reportedDismissUpdatePreviousReached = false;
double reportedDismissUpdateProgress = 0.0;
late DismissDirection reportedDismissUpdateReachedDirection;

DismissDirection reportedDismissDirection = DismissDirection.horizontal;
List<int> dismissedItems = <int>[];

Widget buildTest({
  final Axis scrollDirection = Axis.vertical,
  final DismissDirection dismissDirection = defaultDismissDirection,
  final double? startToEndThreshold,
  final TextDirection textDirection = TextDirection.ltr,
  final Future<bool?> Function(BuildContext context, DismissDirection direction)? confirmDismiss,
  final ScrollController? controller,
  final ScrollPhysics? scrollPhysics,
  final Widget? background,
}) {
  return Directionality(
    textDirection: textDirection,
    child: StatefulBuilder(
      builder: (final BuildContext context, final StateSetter setState) {
        Widget buildDismissibleItem(final int item) {
          return Dismissible(
            dragStartBehavior: DragStartBehavior.down,
            key: ValueKey<int>(item),
            direction: dismissDirection,
            confirmDismiss: confirmDismiss == null ? null : (final DismissDirection direction) {
              return confirmDismiss(context, direction);
            },
            onDismissed: (final DismissDirection direction) {
              setState(() {
                reportedDismissDirection = direction;
                expect(dismissedItems.contains(item), isFalse);
                dismissedItems.add(item);
              });
            },
            onResize: () {
              expect(dismissedItems.contains(item), isFalse);
            },
            onUpdate: (final DismissUpdateDetails details) {
              reportedDismissUpdateReachedDirection = details.direction;
              reportedDismissUpdateReached = details.reached;
              reportedDismissUpdatePreviousReached = details.previousReached;
              reportedDismissUpdateProgress = details.progress;
            },
            background: background,
            dismissThresholds: startToEndThreshold == null
                ? <DismissDirection, double>{}
                : <DismissDirection, double>{DismissDirection.startToEnd: startToEndThreshold},
            crossAxisEndOffset: crossAxisEndOffset,
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: Text(item.toString()),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            physics: scrollPhysics,
            controller: controller,
            dragStartBehavior: DragStartBehavior.down,
            scrollDirection: scrollDirection,
            itemExtent: 100.0,
            children: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8]
              .where((final int i) => !dismissedItems.contains(i))
              .map<Widget>(buildDismissibleItem).toList(),
          ),
        );
      },
    ),
  );
}

typedef DismissMethod = Future<void> Function(WidgetTester tester, Finder finder, { required AxisDirection gestureDirection });

Future<void> dismissElement(final WidgetTester tester, final Finder finder, { required final AxisDirection gestureDirection }) async {
  Offset downLocation;
  Offset upLocation;
  switch (gestureDirection) {
    case AxisDirection.left:
      // getTopRight() returns a point that's just beyond itemWidget's right
      // edge and outside the Dismissible event listener's bounds.
      downLocation = tester.getTopRight(finder) + const Offset(-0.1, 0.0);
      upLocation = tester.getTopLeft(finder) + const Offset(-0.1, 0.0);
    case AxisDirection.right:
      // we do the same thing here to keep the test symmetric
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getTopRight(finder) + const Offset(0.1, 0.0);
    case AxisDirection.up:
      // getBottomLeft() returns a point that's just below itemWidget's bottom
      // edge and outside the Dismissible event listener's bounds.
      downLocation = tester.getBottomLeft(finder) + const Offset(0.0, -0.1);
      upLocation = tester.getTopLeft(finder) + const Offset(0.0, -0.1);
    case AxisDirection.down:
      // again with doing the same here for symmetry
      downLocation = tester.getTopLeft(finder) + const Offset(0.1, 0.0);
      upLocation = tester.getBottomLeft(finder) + const Offset(0.1, 0.0);
  }

  final TestGesture gesture = await tester.startGesture(downLocation);
  await gesture.moveTo(upLocation);
  await gesture.up();
}

Future<void> dragElement(final WidgetTester tester, final Finder finder, { required final AxisDirection gestureDirection, required final double amount }) async {
  Offset delta;
  switch (gestureDirection) {
    case AxisDirection.left:
      delta = Offset(-amount, 0.0);
    case AxisDirection.right:
      delta = Offset(amount, 0.0);
    case AxisDirection.up:
      delta = Offset(0.0, -amount);
    case AxisDirection.down:
      delta = Offset(0.0, amount);
  }
  await tester.drag(finder, delta);
}

Future<void> flingElement(final WidgetTester tester, final Finder finder, { required final AxisDirection gestureDirection, final double initialOffsetFactor = 0.0 }) async {
  Offset delta;
  switch (gestureDirection) {
    case AxisDirection.left:
      delta = const Offset(-300.0, 0.0);
    case AxisDirection.right:
      delta = const Offset(300.0, 0.0);
    case AxisDirection.up:
      delta = const Offset(0.0, -300.0);
    case AxisDirection.down:
      delta = const Offset(0.0, 300.0);
  }
  await tester.fling(finder, delta, 1000.0, initialOffset: delta * initialOffsetFactor);
}

Future<void> flingElementFromZero(final WidgetTester tester, final Finder finder, { required final AxisDirection gestureDirection }) async {
  // This is a special case where we drag in one direction, then fling back so
  // that at the point of release, we're at exactly the point at which we
  // started, but with velocity. This is needed to check a boundary condition
  // in the flinging behavior.
  await flingElement(tester, finder, gestureDirection: gestureDirection, initialOffsetFactor: -1.0);
}

Future<void> dismissItem(
  final WidgetTester tester,
  final int item, {
  required final AxisDirection gestureDirection,
  final DismissMethod mechanism = dismissElement,
}) async {
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);
  await tester.pumpAndSettle();
}

Future<void> dragItem(
    final WidgetTester tester,
    final int item, {
      required final AxisDirection gestureDirection,
      required final double amount,
    }) async {
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await dragElement(tester, itemFinder, gestureDirection: gestureDirection, amount: amount);
  await tester.pump();
}

Future<void> checkFlingItemBeforeMovementEnd(
  final WidgetTester tester,
  final int item, {
  required final AxisDirection gestureDirection,
  final DismissMethod mechanism = rollbackElement,
}) async {
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pump(); // start the slide
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> checkFlingItemAfterMovement(
  final WidgetTester tester,
  final int item, {
  required final AxisDirection gestureDirection,
  final DismissMethod mechanism = rollbackElement,
}) async {
  final Finder itemFinder = find.text(item.toString());
  expect(itemFinder, findsOneWidget);

  await mechanism(tester, itemFinder, gestureDirection: gestureDirection);

  await tester.pump(); // start the slide
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> rollbackElement(final WidgetTester tester, final Finder finder, { required final AxisDirection gestureDirection, final double initialOffsetFactor = 0.0 }) async {
  Offset delta;
  switch (gestureDirection) {
    case AxisDirection.left:
      delta = const Offset(-30.0, 0.0);
    case AxisDirection.right:
      delta = const Offset(30.0, 0.0);
    case AxisDirection.up:
      delta = const Offset(0.0, -30.0);
    case AxisDirection.down:
      delta = const Offset(0.0, 30.0);
  }
  await tester.fling(finder, delta, 1000.0, initialOffset: delta * initialOffsetFactor);
}

class Test1215DismissibleWidget extends StatelessWidget {
  const Test1215DismissibleWidget(this.text, { super.key });

  final String text;

  @override
  Widget build(final BuildContext context) {
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
    // Reset "results" variables.
    reportedDismissDirection = defaultDismissDirection;
    dismissedItems = <int>[];
  });

  testWidgets('Horizontal drag triggers dismiss scrollDirection=vertical', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(),
    );
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

  testWidgets('Horizontal fling triggers dismiss scrollDirection=vertical', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(),
    );
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

  testWidgets('Horizontal fling does not trigger at zero offset, but does otherwise', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        startToEndThreshold: 0.95,
      ),
    );
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

  testWidgets('Vertical drag triggers dismiss scrollDirection=horizontal', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.vertical,
      ),
    );
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

  testWidgets('drag-left with DismissDirection.endToStart triggers dismiss (LTR)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        dismissDirection: DismissDirection.endToStart,
      ),
    );
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

  testWidgets('drag-right with DismissDirection.startToEnd triggers dismiss (LTR)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        dismissDirection: DismissDirection.startToEnd,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-right with DismissDirection.endToStart triggers dismiss (RTL)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        textDirection: TextDirection.rtl,
        dismissDirection: DismissDirection.endToStart,
      ),
    );

    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-left with DismissDirection.startToEnd triggers dismiss (RTL)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        textDirection: TextDirection.rtl,
        dismissDirection: DismissDirection.startToEnd,
      ),
    );
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

  testWidgets('fling-left with DismissDirection.endToStart triggers dismiss (LTR)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        dismissDirection: DismissDirection.endToStart,
      ),
    );
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

  testWidgets('fling-right with DismissDirection.startToEnd triggers dismiss (LTR)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        dismissDirection: DismissDirection.startToEnd,
      ),
    );

    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-right with DismissDirection.endToStart triggers dismiss (RTL)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        textDirection: TextDirection.rtl,
        dismissDirection: DismissDirection.endToStart,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-left with DismissDirection.startToEnd triggers dismiss (RTL)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        textDirection: TextDirection.rtl,
        dismissDirection: DismissDirection.startToEnd,
      ),
    );
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

  testWidgets('drag-up with DismissDirection.up triggers dismiss', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.up,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-down with DismissDirection.down triggers dismiss', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.down,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-up with DismissDirection.up triggers dismiss', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.up,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-down with DismissDirection.down triggers dismiss', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.down,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.up);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('drag-left has no effect on dismissible with a high dismiss threshold', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        startToEndThreshold: 1.0,
      ),
    );
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
  });

  testWidgets('fling-left has no effect on dismissible with a high dismiss threshold', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        startToEndThreshold: 1.0,
      ),
    );
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
  testWidgets('Verify that drag-move events do not assert', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        scrollDirection: Axis.horizontal,
        dismissDirection: DismissDirection.down,
      ),
    );
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
  testWidgets('dismissing bottom then top (smoketest)', (final WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100.0,
            height: 1000.0,
            child: Column(
              children: <Widget>[
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

  testWidgets('Dismissible starts from the full size when collapsing', (final WidgetTester tester) async {
    await tester.pumpWidget(
      buildTest(
        background: const Text('background'),
      ),
    );
    expect(dismissedItems, isEmpty);

    final Finder itemFinder = find.text('0');
    expect(itemFinder, findsOneWidget);
    await dismissElement(tester, itemFinder, gestureDirection: AxisDirection.right);
    await tester.pump();

    expect(find.text('background'), findsOneWidget); // The other four have been culled.
    final RenderBox backgroundBox = tester.firstRenderObject(find.text('background'));
    expect(backgroundBox.size.height, equals(100.0));
  });

  testWidgets('Checking fling item before movementDuration completes', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemBeforeMovementEnd(tester, 0, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);

    await checkFlingItemBeforeMovementEnd(tester, 1, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Checking fling item after movementDuration', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.left, mechanism: flingElement);
    expect(find.text('1'), findsNothing);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Horizontal fling less than threshold', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest(scrollDirection: Axis.horizontal));
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.right);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
  });

  testWidgets('Vertical fling less than threshold', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 0, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.right);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, isEmpty);
  });

  testWidgets('confirmDismiss returns values: true, false, null', (final WidgetTester tester) async {
    late DismissDirection confirmDismissDirection;

    Widget buildFrame(final bool? confirmDismissValue) {
      return buildTest(
          confirmDismiss: (final BuildContext context, final DismissDirection dismissDirection) {
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

  testWidgets('Pending confirmDismiss does not cause errors', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/54990

    late Completer<bool?> completer;
    Widget buildFrame() {
      completer = Completer<bool?>();
      return buildTest(
        confirmDismiss: (final BuildContext context, final DismissDirection dismissDirection) {
          return completer.future;
        },
      );
    }

    // false for _handleDragEnd - when dragged to the end and released

    await tester.pumpWidget(buildFrame());

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await tester.pumpWidget(const SizedBox());
    completer.complete(false);
    await tester.pump();

    // true for _handleDragEnd - when dragged to the end and released

    await tester.pumpWidget(buildFrame());

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await tester.pumpWidget(const SizedBox());
    completer.complete(true);
    await tester.pump();

    // false for _handleDismissStatusChanged - when fling reaches the end

    await tester.pumpWidget(buildFrame());

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await tester.pumpWidget(const SizedBox());
    completer.complete(false);
    await tester.pump();

    // true for _handleDismissStatusChanged - when fling reaches the end

    await tester.pumpWidget(buildFrame());

    await dismissItem(tester, 0, gestureDirection: AxisDirection.right, mechanism: flingElement);
    expect(find.text('0'), findsOneWidget);
    expect(dismissedItems, isEmpty);

    await tester.pumpWidget(const SizedBox());
    completer.complete(true);
    await tester.pump();
  });

  testWidgets('Dismissible cannot be dragged with pending confirmDismiss', (final WidgetTester tester) async {
    final Completer<bool?> completer = Completer<bool?>();
    await tester.pumpWidget(
      buildTest(
        confirmDismiss: (final BuildContext context, final DismissDirection dismissDirection) {
          return completer.future;
        },
      ),
    );

    // Trigger confirmDismiss call.
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    final Offset position = tester.getTopLeft(find.text('0'));

    // Try to move and verify it has not moved.
    Offset dragAt = tester.getTopLeft(find.text('0'));
    dragAt = Offset(100.0, dragAt.dy);
    final TestGesture gesture = await tester.startGesture(dragAt);
    await gesture.moveTo(dragAt + const Offset(100.0, 0.0));
    await gesture.up();
    await tester.pump();
    expect(tester.getTopLeft(find.text('0')), position);
  });

  testWidgets('Drag to end and release - items does not get stuck if confirmDismiss returns false', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/87556

    final Completer<bool?> completer = Completer<bool?>();
    await tester.pumpWidget(
      buildTest(
        confirmDismiss: (final BuildContext context, final DismissDirection dismissDirection) {
          return completer.future;
        },
      ),
    );

    final Offset position = tester.getTopLeft(find.text('0'));
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    completer.complete(false);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('0')), position);
  });

  testWidgets('Dismissible with null resizeDuration calls onDismissed immediately', (final WidgetTester tester) async {
    bool resized = false;
    bool dismissed = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Dismissible(
          dragStartBehavior: DragStartBehavior.down,
          key: UniqueKey(),
          resizeDuration: null,
          onDismissed: (final DismissDirection direction) {
            dismissed = true;
          },
          onResize: () {
            resized = true;
          },
          child: const SizedBox(
            width: 100.0,
            height: 100.0,
            child: Text('0'),
          ),
        ),
      ),
    );

    await dismissElement(tester, find.text('0'), gestureDirection: AxisDirection.right);
    await tester.pump();
    expect(dismissed, true);
    expect(resized, false);
  });

  testWidgets('setState that does not remove the Dismissible from tree should throw Error', (final WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: StatefulBuilder(
        builder: (final BuildContext context, final StateSetter setState) {
          return ListView(
            dragStartBehavior: DragStartBehavior.down,
            itemExtent: 100.0,
            children: <Widget>[
              Dismissible(
                dragStartBehavior: DragStartBehavior.down,
                key: const ValueKey<int>(1),
                onDismissed: (final DismissDirection direction) {
                  setState(() {
                    reportedDismissDirection = direction;
                    expect(dismissedItems.contains(1), isFalse);
                    dismissedItems.add(1);
                  });
                },
                crossAxisEndOffset: crossAxisEndOffset,
                child: SizedBox(
                  width: 100.0,
                  height: 100.0,
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

  testWidgets('Dismissible.behavior should behave correctly during hit testing', (final WidgetTester tester) async {
    bool didReceivePointerDown = false;

    Widget buildStack({required final Widget child}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Listener(
              onPointerDown: (final _) {
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

    Future<void> pumpWidgetTree(final HitTestBehavior behavior) {
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

  testWidgets('DismissDirection.none does not trigger dismiss', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest(
      dismissDirection: DismissDirection.none,
      scrollPhysics: const NeverScrollableScrollPhysics(),
    ));
    expect(dismissedItems, isEmpty);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('DismissDirection.none does not prevent scrolling', (final WidgetTester tester) async {
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(
      buildTest(
        controller: controller,
        dismissDirection: DismissDirection.none,
      ),
    );
    expect(dismissedItems, isEmpty);
    expect(controller.offset, 0.0);

    await dismissItem(tester, 0, gestureDirection: AxisDirection.left);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.right);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.down);
    expect(controller.offset, 0.0);
    await dismissItem(tester, 0, gestureDirection: AxisDirection.up);
    expect(controller.offset, 100.0);
    controller.dispose();
  });

  testWidgets('onUpdate', (final WidgetTester tester) async {
    await tester.pumpWidget(buildTest(
      scrollDirection: Axis.horizontal,
    ));
    expect(dismissedItems, isEmpty);

    // Unsuccessful dismiss, fractional progress reported
    await dragItem(tester, 0, gestureDirection: AxisDirection.right, amount: 20);
    expect(reportedDismissUpdateProgress, 0.2);

    // Successful dismiss therefore threshold has been reached
    await dismissItem(tester, 0, mechanism: flingElement, gestureDirection: AxisDirection.left);
    expect(find.text('0'), findsNothing);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissUpdateReachedDirection, DismissDirection.endToStart);
    expect(reportedDismissUpdateReached, true);
    expect(reportedDismissUpdatePreviousReached, true);
    expect(reportedDismissUpdateProgress, 1.0);

    // Unsuccessful dismiss, threshold has not been reached
    await checkFlingItemAfterMovement(tester, 1, gestureDirection: AxisDirection.right);
    expect(find.text('1'), findsOneWidget);
    expect(dismissedItems, equals(<int>[0]));
    expect(reportedDismissUpdateReachedDirection, DismissDirection.startToEnd);
    expect(reportedDismissUpdateReached, false);
    expect(reportedDismissUpdatePreviousReached, false);
    expect(reportedDismissUpdateProgress, 0.0);

    // Another successful dismiss from another direction
    await dismissItem(tester, 1, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('1'), findsNothing);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissUpdateReachedDirection, DismissDirection.startToEnd);
    expect(reportedDismissUpdateReached, true);
    expect(reportedDismissUpdatePreviousReached, true);
    expect(reportedDismissUpdateProgress, 1.0);

    await tester.pumpWidget(buildTest(
      scrollDirection: Axis.horizontal,
      confirmDismiss: (final BuildContext context, final DismissDirection dismissDirection) {
        return Future<bool>.value(false);
      },
    ));

    // Threshold has been reached but dismiss was not confirmed
    await dismissItem(tester, 2, mechanism: flingElement, gestureDirection: AxisDirection.right);
    expect(find.text('2'), findsOneWidget);
    expect(dismissedItems, equals(<int>[0, 1]));
    expect(reportedDismissUpdateReachedDirection, DismissDirection.startToEnd);
    expect(reportedDismissUpdateReached, false);
    expect(reportedDismissUpdatePreviousReached, false);
    expect(reportedDismissUpdateProgress, 0.0);
  });

  testWidgets('Change direction does not lose child state', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/108961
    Widget buildFrame(final DismissDirection direction) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Dismissible(
          dragStartBehavior: DragStartBehavior.down,
          direction: direction,
          key: const Key('Dismissible'),
          resizeDuration: null,
          child: const SizedBox(
            width: 100.0,
            height: 100.0,
            child: Text('I Love Flutter!'),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(DismissDirection.horizontal));
    final RenderBox textRenderObjectBegin = tester.renderObject(find.text('I Love Flutter!'));

    await tester.pumpWidget(buildFrame(DismissDirection.none));
    final RenderBox textRenderObjectEnd = tester.renderObject(find.text('I Love Flutter!'));

    expect(identical(textRenderObjectBegin, textRenderObjectEnd), true);
  });
}
