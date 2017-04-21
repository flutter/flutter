// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

const Color selectedColor = const Color(0xFF00FF00);
const Color unselectedColor = Colors.transparent;

Widget buildFrame(TabController tabController) {
  return new Theme(
    data: new ThemeData(accentColor: selectedColor),
    child: new SizedBox.expand(
      child: new Center(
        child: new SizedBox(
          width: 400.0,
          height: 400.0,
          child: new Column(
            children: <Widget>[
              new TabPageSelector(controller: tabController),
              new Flexible(
                child: new TabBarView(
                  controller: tabController,
                  children: <Widget>[
                    const Center(child: const Text('0')),
                    const Center(child: const Text('1')),
                    const Center(child: const Text('2')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

List<Color> indicatorColors(WidgetTester tester) {
  final Iterable<TabPageSelectorIndicator> indicators = tester.widgetList(
    find.descendant(
      of: find.byType(TabPageSelector),
      matching: find.byType(TabPageSelectorIndicator)
    )
  );
  return indicators.map((TabPageSelectorIndicator indicator) => indicator.backgroundColor).toList();
}

void main() {
  testWidgets('PageSelector responds correctly to setting the TabController index', (WidgetTester tester) async {
    final TabController tabController = new TabController(
      vsync: const TestVSync(),
      length: 3,
    );
    await tester.pumpWidget(buildFrame(tabController));

    expect(tabController.index, 0);
    expect(indicatorColors(tester), const <Color>[selectedColor, unselectedColor, unselectedColor]);

    tabController.index = 1;
    await tester.pump();
    expect(tabController.index, 1);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    tabController.index = 2;
    await tester.pump();
    expect(tabController.index, 2);
    expect(indicatorColors(tester), const <Color>[unselectedColor, unselectedColor, selectedColor]);
  });

  testWidgets('PageSelector responds correctly to TabController.animateTo()', (WidgetTester tester) async {
    final TabController tabController = new TabController(
      vsync: const TestVSync(),
      length: 3,
    );
    await tester.pumpWidget(buildFrame(tabController));

    expect(tabController.index, 0);
    expect(indicatorColors(tester), const <Color>[selectedColor, unselectedColor, unselectedColor]);

    tabController.animateTo(1, duration: const Duration(milliseconds: 200));
    await tester.pump();
    // Verify that indicator 0's color is becoming increasingly transparent,
    /// and indicator 1's color is becoming increasingly opaque during the
    // 200ms animation. Indicator 2 remains transparent throughout.
    await tester.pump(const Duration(milliseconds: 10));
    List<Color> colors = indicatorColors(tester);
    expect(colors[0].alpha, greaterThan(colors[1].alpha));
    expect(colors[2], unselectedColor);
    await tester.pump(const Duration(milliseconds: 175));
    colors = indicatorColors(tester);
    expect(colors[0].alpha, lessThan(colors[1].alpha));
    expect(colors[2], unselectedColor);
    await tester.pumpAndSettle();
    expect(tabController.index, 1);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    tabController.animateTo(2, duration: const Duration(milliseconds: 200));
    await tester.pump();
    // Same animation test as above for indicators 1 and 2.
    await tester.pump(const Duration(milliseconds: 10));
    colors = indicatorColors(tester);
    expect(colors[1].alpha, greaterThan(colors[2].alpha));
    expect(colors[0], unselectedColor);
    await tester.pump(const Duration(milliseconds: 175));
    colors = indicatorColors(tester);
    expect(colors[1].alpha, lessThan(colors[2].alpha));
    expect(colors[0], unselectedColor);
    await tester.pumpAndSettle();
    expect(tabController.index, 2);
    expect(indicatorColors(tester), const <Color>[unselectedColor, unselectedColor, selectedColor]);
  });

  testWidgets('PageSelector responds correctly to TabBarView drags', (WidgetTester tester) async {
    final TabController tabController = new TabController(
      vsync: const TestVSync(),
      initialIndex: 1,
      length: 3,
    );
    await tester.pumpWidget(buildFrame(tabController));

    expect(tabController.index, 1);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));

    // Drag to the left moving the selection towards indicator 2. Indicator 2's
    // opacity should increase and Indicator 1's opacity should decrease.
    await gesture.moveBy(const Offset(-100.0, 0.0));
    await tester.pumpAndSettle();
    List<Color> colors = indicatorColors(tester);
    expect(colors[1].alpha, greaterThan(colors[2].alpha));
    expect(colors[0], unselectedColor);

    // Drag back to where we started.
    await gesture.moveBy(const Offset(100.0, 0.0));
    await tester.pumpAndSettle();
    colors = indicatorColors(tester);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    // Drag to the left moving the selection towards indicator 0. Indicator 0's
    // opacity should increase and Indicator 1's opacity should decrease.
    await gesture.moveBy(const Offset(100.0, 0.0));
    await tester.pumpAndSettle();
    colors = indicatorColors(tester);
    expect(colors[1].alpha, greaterThan(colors[0].alpha));
    expect(colors[2], unselectedColor);

    // Drag back to where we started.
    await gesture.moveBy(const Offset(-100.0, 0.0));
    await tester.pumpAndSettle();
    colors = indicatorColors(tester);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    // Completing the gesture doesn't change anything
    await gesture.up();
    await tester.pumpAndSettle();
    colors = indicatorColors(tester);
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

    // Fling to the left, selects indicator 2
    await tester.fling(find.byType(TabBarView), const Offset(-100.0, 0.0), 1000.0);
    await tester.pumpAndSettle();
    expect(indicatorColors(tester), const <Color>[unselectedColor, unselectedColor, selectedColor]);

    // Fling to the right, selects indicator 1
    await tester.fling(find.byType(TabBarView), const Offset(100.0, 0.0), 1000.0);
    await tester.pumpAndSettle();
    expect(indicatorColors(tester), const <Color>[unselectedColor, selectedColor, unselectedColor]);

  });

}
