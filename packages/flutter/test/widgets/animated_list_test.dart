// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedList initialItemCount', (WidgetTester tester) async {
    final Map<int, Animation<double>> animations = <int, Animation<double>>{};

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedList(
          initialItemCount: 2,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            animations[index] = animation;
            return SizedBox(
              height: 100.0,
              child: Center(
                child: Text('item $index'),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(animations.containsKey(0), true);
    expect(animations.containsKey(1), true);
    expect(animations[0].value, 1.0);
    expect(animations[1].value, 1.0);
  });

  testWidgets('AnimatedList insert', (WidgetTester tester) async {
    final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedList(
          key: listKey,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            return SizeTransition(
              key: ValueKey<int>(index),
              axis: Axis.vertical,
              sizeFactor: animation,
              child: SizedBox(
                height: 100.0,
                child: Center(
                  child: Text('item $index'),
                ),
              ),
            );
          },
        ),
      ),
    );

    double itemHeight(int index) => tester.getSize(find.byKey(ValueKey<int>(index), skipOffstage: false)).height;
    double itemTop(int index) => tester.getTopLeft(find.byKey(ValueKey<int>(index), skipOffstage: false)).dy;
    double itemBottom(int index) => tester.getBottomLeft(find.byKey(ValueKey<int>(index), skipOffstage: false)).dy;

    listKey.currentState.insertItem(0, duration: const Duration(milliseconds: 100));
    await tester.pump();

    // Newly inserted item 0's height should animate from 0 to 100
    expect(itemHeight(0), 0.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(itemHeight(0), 50.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(itemHeight(0), 100.0);

    // The list now contains one fully expanded item at the top:
    expect(find.text('item 0'), findsOneWidget);
    expect(itemTop(0), 0.0);
    expect(itemBottom(0), 100.0);

    listKey.currentState.insertItem(0, duration: const Duration(milliseconds: 100));
    listKey.currentState.insertItem(0, duration: const Duration(milliseconds: 100));
    await tester.pump();

    // The height of the newly inserted items at index 0 and 1 should animate from 0 to 100.
    // The height of the original item, now at index 2, should remain 100.
    expect(itemHeight(0), 0.0);
    expect(itemHeight(1), 0.0);
    expect(itemHeight(2), 100.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(itemHeight(0), 50.0);
    expect(itemHeight(1), 50.0);
    expect(itemHeight(2), 100.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(itemHeight(0), 100.0);
    expect(itemHeight(1), 100.0);
    expect(itemHeight(2), 100.0);

    // The newly inserted "item 1" and "item 2" appear above "item 0"
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(itemTop(0), 0.0);
    expect(itemBottom(0), 100.0);
    expect(itemTop(1), 100.0);
    expect(itemBottom(1), 200.0);
    expect(itemTop(2), 200.0);
    expect(itemBottom(2), 300.0);
  });

  testWidgets('AnimatedList remove', (WidgetTester tester) async {
    final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
    final List<int> items = <int>[0, 1, 2];

    Widget buildItem(BuildContext context, int item, Animation<double> animation) {
      return SizeTransition(
        key: ValueKey<int>(item),
        axis: Axis.vertical,
        sizeFactor: animation,
        child: SizedBox(
          height: 100.0,
          child: Center(
            child: Text('item $item', textDirection: TextDirection.ltr),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedList(
          key: listKey,
          initialItemCount: 3,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            return buildItem(context, items[index], animation);
          },
        ),
      ),
    );

    double itemTop(int index) => tester.getTopLeft(find.byKey(ValueKey<int>(index))).dy;
    double itemBottom(int index) => tester.getBottomLeft(find.byKey(ValueKey<int>(index))).dy;

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);

    items.removeAt(0);
    listKey.currentState.removeItem(0,
      (BuildContext context, Animation<double> animation) => buildItem(context, 0, animation),
      duration: const Duration(milliseconds: 100),
    );

    // Items 0, 1, 2 at 0, 100, 200. All heights 100.
    expect(itemTop(0), 0.0);
    expect(itemBottom(0), 100.0);
    expect(itemTop(1), 100.0);
    expect(itemBottom(1), 200.0);
    expect(itemTop(2), 200.0);
    expect(itemBottom(2), 300.0);

    // Newly removed item 0's height should animate from 100 to 0 over 100ms

    // Items 0, 1, 2 at 0, 50, 150. Item 0's height is 50.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(itemTop(0), 0.0);
    expect(itemBottom(0), 50.0);
    expect(itemTop(1), 50.0);
    expect(itemBottom(1), 150.0);
    expect(itemTop(2), 150.0);
    expect(itemBottom(2), 250.0);

    // Items 1, 2 at 0, 100.
    await tester.pumpAndSettle();
    expect(itemTop(1), 0.0);
    expect(itemBottom(1), 100.0);
    expect(itemTop(2), 100.0);
    expect(itemBottom(2), 200.0);
   });
}
