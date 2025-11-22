import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/sliver.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to get the scroll offset of a Scrollable.
double getScrollOffset(WidgetTester tester) {
  final ScrollableState scrollable = tester.state(find.byType(Scrollable));
  return scrollable.position.pixels;
}

// Helper to get the position of the item's container in the viewport.
Rect getItemContainerRect(WidgetTester tester, int index) {
  final Finder itemFinder = find.byKey(ValueKey<int>(index), skipOffstage: false);
  if (tester.any(itemFinder)) {
    return tester.getRect(itemFinder);
  }
  return Rect.zero;
}

class _TestScaffold extends StatefulWidget {
  const _TestScaffold({
    required super.key,
    required this.itemExtents,
    // ignore: unused_element_parameter
    this.initialAnchor = SliverIndexAnchor.zero,
  });
  final List<double> itemExtents;
  final SliverIndexAnchor initialAnchor;

  @override
  _TestScaffoldState createState() => _TestScaffoldState();
}

class _TestScaffoldState extends State<_TestScaffold> {
  late final IndexedScrollController controller;
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  late SliverIndexAnchor anchor;
  late List<double> currentExtents;

  @override
  void initState() {
    super.initState();
    controller = IndexedScrollController();
    anchor = widget.initialAnchor;
    currentExtents = widget.itemExtents;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateState({List<double>? newItemExtents, SliverIndexAnchor? newAnchor}) {
    setState(() {
      if (newItemExtents != null) {
        currentExtents = newItemExtents;
      }
      if (newAnchor != null) {
        anchor = newAnchor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverIndexedVariedExtentList(
              indexedScrollController: controller,
              itemPositionsListener: itemPositionsListener,
              anchor: anchor,
              itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) =>
                  currentExtents[index],
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Container(
                  key: ValueKey<int>(index),
                  height: currentExtents[index],
                  alignment: Alignment.center,
                  color: Colors.blue[100 * (index % 9)],
                  child: Text('Item $index'),
                ),
                childCount: currentExtents.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  const int itemCount = 500;
  const double screenHeight = 600.0;
  const double itemHeight = 60.0; // 10 items visible on screen at once

  group('Core Functionality', () {
    testWidgets('jumpToIndex positions item correctly', (WidgetTester tester) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      await tester.pumpAndSettle();

      final IndexedScrollController controller = key.currentState!.controller;

      // Test jump to top
      controller.jumpToIndex(100);
      await tester.pumpAndSettle();
      expect(find.text('Item 100'), findsOneWidget);
      expect(getItemContainerRect(tester, 100).top, 0.0);

      // Test jump to center
      controller.jumpToIndex(250, alignment: 0.5);
      await tester.pumpAndSettle();
      final Rect item250Rect = getItemContainerRect(tester, 250);
      final double expectedTop = (screenHeight - item250Rect.height) / 2.0;
      expect(item250Rect.top, closeTo(expectedTop, 0.01));

      // Test jump to bottom
      controller.jumpToIndex(300, alignment: 1.0);
      await tester.pumpAndSettle();
      final Rect item300Rect = getItemContainerRect(tester, 300);
      expect(item300Rect.bottom, closeTo(screenHeight, 0.01));
    });

    testWidgets('Anchor holds item position when extents change', (WidgetTester tester) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> currentExtents = List<double>.generate(
        itemCount,
        (int index) => 60.0 + (index % 10) * 5.0,
      );

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: currentExtents));
      final IndexedScrollController controller = key.currentState!.controller;

      // 1. Scroll to item 50 and set it as the anchor.
      controller.jumpToIndex(50, alignment: 0.5);
      await tester.pumpAndSettle();
      key.currentState!.updateState(newAnchor: const SliverIndexAnchor(index: 50, alignment: 0.5));
      await tester.pump();

      final Rect initialRect = getItemContainerRect(tester, 50);
      final double initialOffset = getScrollOffset(tester);

      // 2. Change the heights of all items before the anchor.
      double addedHeight = 0;
      final List<double> newExtents = List<double>.from(currentExtents);
      for (int i = 0; i < 50; i++) {
        newExtents[i] += 50.0;
        addedHeight += 50.0;
      }

      // 3. Rebuild with new extents; the anchor should hold the position.
      key.currentState!.updateState(newItemExtents: newExtents);
      await tester.pump(); // This frame applies the scroll correction.
      await tester.pumpAndSettle(); // Settle any physics.

      final Rect finalRect = getItemContainerRect(tester, 50);
      final double finalOffset = getScrollOffset(tester);

      // The item's visual position on screen should be the same.
      expect(finalRect.top, closeTo(initialRect.top, 0.01));
      // The scroll offset should have increased by the total added height.
      expect(finalOffset, closeTo(initialOffset + addedHeight, 0.01));
    });
  });

  group('ItemPositionsListener and Scrolling', () {
    testWidgets('Listener reports correct positions for initial build', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      await tester.pumpAndSettle();

      final Iterable<SliverIndexedItemPosition> positions =
          key.currentState!.itemPositionsListener.itemPositions.value;
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 9'), findsOneWidget);
      expect(find.text('Item 10'), findsNothing);

      expect(
        positions.firstWhere((SliverIndexedItemPosition p) => p.index == 0).itemLeadingEdge,
        0,
      );
      expect(
        positions.firstWhere((SliverIndexedItemPosition p) => p.index == 9).itemTrailingEdge,
        1,
      );
    });

    testWidgets('Listener reports correct positions after jump', (WidgetTester tester) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      final IndexedScrollController controller = key.currentState!.controller;
      final ItemPositionsListener listener = key.currentState!.itemPositionsListener;

      controller.jumpToIndex(20, alignment: 1.0);
      await tester.pumpAndSettle();

      expect(find.text('Item 11'), findsOneWidget);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 21'), findsNothing);

      final Iterable<SliverIndexedItemPosition> positions = listener.itemPositions.value;
      final SliverIndexedItemPosition position20 = positions.firstWhere(
        (SliverIndexedItemPosition p) => p.index == 20,
      );
      expect(position20.itemTrailingEdge, closeTo(1.0, 0.001));
    });

    testWidgets('Listener reports correct positions after jump to middle', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      final IndexedScrollController controller = key.currentState!.controller;
      final ItemPositionsListener listener = key.currentState!.itemPositionsListener;

      controller.jumpToIndex(20, alignment: 0.5);
      await tester.pumpAndSettle();

      final Iterable<SliverIndexedItemPosition> positions = listener.itemPositions.value;
      final SliverIndexedItemPosition position20 = positions.firstWhere(
        (SliverIndexedItemPosition p) => p.index == 20,
      );

      const double expectedLeadingEdge =
          (screenHeight - itemHeight) / (2 * screenHeight); // (600 - 60) / 1200 = 0.45
      expect(position20.itemLeadingEdge, closeTo(expectedLeadingEdge, 0.01));
      expect(
        position20.itemTrailingEdge,
        closeTo(expectedLeadingEdge + itemHeight / screenHeight, 0.01),
      );
    });

    testWidgets('Listener reports correct positions after manual drag', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      final IndexedScrollController controller = key.currentState!.controller;
      final ItemPositionsListener listener = key.currentState!.itemPositionsListener;

      controller.jumpToIndex(5);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, -2 * itemHeight));
      await tester.pumpAndSettle();

      expect(find.text('Item 6'), findsNothing);
      expect(find.text('Item 7'), findsOneWidget);
      expect(find.text('Item 16'), findsOneWidget);
      expect(find.text('Item 17'), findsNothing);

      final Iterable<SliverIndexedItemPosition> positions = listener.itemPositions.value;
      expect(
        positions.firstWhere((SliverIndexedItemPosition p) => p.index == 7).itemLeadingEdge,
        closeTo(0, 0.01),
      );
    });

    testWidgets('animateToIndex works for item not on screen', (WidgetTester tester) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> itemExtents = List<double>.generate(itemCount, (int index) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: itemExtents));
      final IndexedScrollController controller = key.currentState!.controller;
      final ItemPositionsListener listener = key.currentState!.itemPositionsListener;

      controller.animateToIndex(
        100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );

      await tester.pumpAndSettle();

      expect(find.text('Item 99'), findsNothing);
      expect(find.text('Item 100'), findsOneWidget);

      final Iterable<SliverIndexedItemPosition> positions = listener.itemPositions.value;
      expect(
        positions.firstWhere((SliverIndexedItemPosition p) => p.index == 100).itemLeadingEdge,
        closeTo(0, 0.01),
      );
    });

    testWidgets('Changing itemCount works correctly', (WidgetTester tester) async {
      final GlobalKey<_TestScaffoldState> key = GlobalKey<_TestScaffoldState>();
      final List<double> initialExtents = List<double>.generate(200, (int i) => itemHeight);

      await tester.pumpWidget(_TestScaffold(key: key, itemExtents: initialExtents));
      final IndexedScrollController controller = key.currentState!.controller;

      controller.jumpToIndex(150);
      await tester.pumpAndSettle();
      expect(find.text('Item 150'), findsOneWidget);

      // Reduce the item count
      final List<double> newExtents = List<double>.generate(100, (int i) => itemHeight);
      key.currentState!.updateState(newItemExtents: newExtents);
      await tester.pumpAndSettle();

      // The scroll position should have been corrected.
      expect(find.text('Item 150'), findsNothing);
      expect(find.text('Item 99'), findsOneWidget);
      expect(getItemContainerRect(tester, 99).bottom, closeTo(screenHeight, 0.01));
    });
  });
}
