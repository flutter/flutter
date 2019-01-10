// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverList reverse children (with keys)', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    const double itemHeight = 300.0;
    const double viewportHeight = 500.0;

    const double scrollPosition = 18 * itemHeight;
    final ScrollController controller = ScrollController(initialScrollOffset: scrollPosition);

    await tester.pumpWidget(_buildSliverList(
      items: items,
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    await tester.pumpAndSettle();

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 19'), findsOneWidget);

    await tester.pumpWidget(_buildSliverList(
      items: items.reversed.toList(),
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    final int frames = await tester.pumpAndSettle();
    expect(frames, 1); // ensures that there is no (animated) bouncing of the scrollable

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 19'), findsNothing);
    expect(find.text('Tile 18'), findsNothing);
    expect(find.text('Tile 1'), findsOneWidget);
    expect(find.text('Tile 0'), findsOneWidget);

    controller.jumpTo(0.0);
    await tester.pumpAndSettle();

    expect(controller.offset, 0.0);
    expect(find.text('Tile 19'), findsOneWidget);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 0'), findsNothing);
  });

  testWidgets('SliverList replace children (with keys)', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    const double itemHeight = 300.0;
    const double viewportHeight = 500.0;

    const double scrollPosition = 18 * itemHeight;
    final ScrollController controller = ScrollController(initialScrollOffset: scrollPosition);

    await tester.pumpWidget(_buildSliverList(
      items: items,
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    await tester.pumpAndSettle();

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 19'), findsOneWidget);

    await tester.pumpWidget(_buildSliverList(
      items: items.map<int>((int i) => i + 100).toList(),
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    final int frames = await tester.pumpAndSettle();
    expect(frames, 1); // ensures that there is no (animated) bouncing of the scrollable

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 18'), findsNothing);
    expect(find.text('Tile 19'), findsNothing);

    expect(find.text('Tile 100'), findsNothing);
    expect(find.text('Tile 101'), findsNothing);
    expect(find.text('Tile 118'), findsOneWidget);
    expect(find.text('Tile 119'), findsOneWidget);

    controller.jumpTo(0.0);
    await tester.pumpAndSettle();

    expect(controller.offset, 0.0);
    expect(find.text('Tile 100'), findsOneWidget);
    expect(find.text('Tile 101'), findsOneWidget);
    expect(find.text('Tile 118'), findsNothing);
    expect(find.text('Tile 119'), findsNothing);
  });

  testWidgets('SliverList replace with shorter children list (with keys)', (WidgetTester tester) async {
    final List<int> items = List<int>.generate(20, (int i) => i);
    const double itemHeight = 300.0;
    const double viewportHeight = 500.0;

    final double scrollPosition = items.length * itemHeight - viewportHeight;
    final ScrollController controller = ScrollController(initialScrollOffset: scrollPosition);

    await tester.pumpWidget(_buildSliverList(
      items: items,
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    await tester.pumpAndSettle();

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 17'), findsNothing);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 19'), findsOneWidget);

    await tester.pumpWidget(_buildSliverList(
      items: items.sublist(0, items.length - 1),
      controller: controller,
      itemHeight: itemHeight,
      viewportHeight: viewportHeight,
    ));
    final int frames = await tester.pumpAndSettle();
    expect(frames, greaterThan(1)); // ensure animation to bring tile17 into view

    expect(controller.offset, scrollPosition - itemHeight);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 17'), findsOneWidget);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 19'), findsNothing);
  });
}

Widget _buildSliverList({
  List<int> items = const <int>[],
  ScrollController controller,
  double itemHeight = 500.0,
  double viewportHeight = 300.0,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        height: viewportHeight,
        child: CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                  return Container(
                    key: ValueKey<int>(items[i]),
                    height: itemHeight,
                    child: Text('Tile ${items[i]}'),
                  );
                },
                childCount: items.length,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
