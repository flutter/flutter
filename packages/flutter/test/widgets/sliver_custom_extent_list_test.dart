// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestItem extends StatelessWidget {
  const TestItem({ Key? key, required this.item, this.width, this.height }) : super(key: key);
  final int item;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text('Item $item', textDirection: TextDirection.ltr),
    );
  }
}

Widget buildFrame({ required double itemExtent, required double extentScale, required int itemCount, int? count, Axis? scrollDirection }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: CustomScrollView(
      scrollDirection: scrollDirection ?? Axis.vertical,
      slivers: <Widget>[
        SliverCustomExtentList(
          extentAssistant: _TestSliverCustomExtentListAssistant(
            basicExtent: itemExtent,
            extentScale: extentScale,
            itemCount: itemCount,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (scrollDirection == Axis.horizontal) {
                return TestItem(item: index, width: (index % itemCount == 0) ? itemExtent : itemExtent * extentScale);
              } else {
                return TestItem(item: index, height: (index % itemCount == 0) ? itemExtent : itemExtent * extentScale);
              }
            },
            childCount: count,
          ),
        ),
      ],
    ),
  );
}

/// This test list is composed of several sections. Every section has items as
/// many as `itemCount`, the first item length is `basicExtent` and the others
/// are `basicExtent * extentScale`, show as:
/// |------------|------------|        |------------|
/// |  section0  |  section1  | ...... |  sectionN  |
/// |------------|------------|        |------------|
///            /                \
///          /                    \
///        /                        \
///      /                            \
///    /                                \
///  /                                    \
/// |-----|-----------|        |-----------|
/// |item0|   item1   | ...... |   itemN   |
/// |-----|-----------|        |-----------|
class _TestSliverCustomExtentListAssistant implements SliverCustomExtentListAssistant {
  const _TestSliverCustomExtentListAssistant({
    required this.basicExtent,
    required this.extentScale,
    required this.itemCount,
  }) : assert(itemCount >= 2);

  final double basicExtent;
  final double extentScale;
  final int itemCount;

  @override
  double indexToLayoutOffset(int index) {
    return index * basicExtent * extentScale - (index / itemCount).ceil() * basicExtent * (extentScale - 1.0);
  }

  @override
  int getChildIndexForScrollOffset(double scrollOffset) {
    final double sectionLength = basicExtent + basicExtent * extentScale * (itemCount - 1);
    final int sectionCount = (scrollOffset / sectionLength).floor();
    int remainItemCount = scrollOffset % sectionLength > basicExtent ? 1 : 0;
    if (remainItemCount > 0) {
      remainItemCount += ((scrollOffset % sectionLength - basicExtent) / (basicExtent * extentScale)).floor();
    }
    return sectionCount * itemCount + remainItemCount;
  }
}

void main() {
  testWidgets('SliverCustomExtentList vertical scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(itemExtent: 100.0, extentScale: 2.0, itemCount: 5, count: 20));

    // The viewport is 600 pixels high, lazily created items are one 100 pixels high followed by three 200 pixels high.
    final Finder item = find.widgetWithText(Container, 'Item 0');
    expect(item, findsOneWidget);
    expect(tester.getTopLeft(item).dy, 0.0);
    expect(tester.getSize(item).height, 100.0);
    for (int i = 1; i <= 3; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dy, i * 200.0 - 100.0);
      expect(tester.getSize(item).height, 200.0);
    }
    for (int i = 4; i < 20; i += 1)
      expect(find.text('Item $i'), findsNothing);

    // Fling scroll to the end.
    await tester.fling(find.text('Item 2'), const Offset(0.0, -200.0), 8000.0);
    await tester.pumpAndSettle();

    for (int i = 19; i >= 17; i -= 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 16; i >= 0; i -= 1)
      expect(find.text('Item $i'), findsNothing);
  });

  testWidgets('SliverCustomExtentList horizontal scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(itemExtent: 100.0, extentScale: 2.0, itemCount: 5, count: 20, scrollDirection: Axis.horizontal));

    // The viewport is 800 pixels wide, lazily created items are one 100 pixels wide followed by four 200 pixels wide.
    final Finder item = find.widgetWithText(Container, 'Item 0');
    expect(item, findsOneWidget);
    expect(tester.getTopLeft(item).dx, 0.0);
    expect(tester.getSize(item).width, 100.0);
    for (int i = 1; i <= 4; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dx, i * 200 - 100.0);
      expect(tester.getSize(item).width, 200.0);
    }
    for (int i = 5; i < 20; i += 1)
      expect(find.text('Item $i'), findsNothing);

    // Fling scroll to the end.
    await tester.fling(find.text('Item 2'), const Offset(-300.0, 0.0), 8000.0);
    await tester.pumpAndSettle();

    for (int i = 19; i >= 16; i -= 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 15; i >= 0; i -= 1)
      expect(find.text('Item $i'), findsNothing);
  });

  testWidgets('SliverCustomExtentList change custom extent', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(itemExtent: 100.0, extentScale: 2.0, itemCount: 5, count: 10));

    // The viewport is 600 pixels high, lazily created items are one 100 pixels high followed by three 200 pixels high.
    for (int i = 0; i <= 3; i += 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 4; i < 10; i += 1)
      expect(find.text('Item $i'), findsNothing);

    await tester.pumpWidget(buildFrame(itemExtent: 200.0, extentScale: 2.0, itemCount: 5, count: 10));

    // The viewport is 600 pixels high, lazily created items are one 200 pixels high followed by one 400 pixels high.
    for (int i = 0; i <= 1; i += 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 2; i < 10; i += 1)
      expect(find.text('Item $i'), findsNothing);
  });
}
