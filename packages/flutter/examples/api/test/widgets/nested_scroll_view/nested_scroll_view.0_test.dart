// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/nested_scroll_view/nested_scroll_view.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows all elements', (WidgetTester tester) async {
    await tester.pumpWidget(const example.NestedScrollViewExampleApp());
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.byType(CustomScrollView), findsAtLeast(1));
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 14'), findsNothing);
    expect(find.text('Item 14', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Item \d\d?'), skipOffstage: false),
      findsAtLeast(15),
    );

    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(RegExp(r'Item \d\d?'), skipOffstage: false),
      findsAtLeast(15),
    );
  });

  testWidgets('Shrinks app bar on scroll', (WidgetTester tester) async {
    await tester.pumpWidget(const example.NestedScrollViewExampleApp());

    final double initialAppBarHeight = tester
        .getTopLeft(find.byType(TabBarView))
        .dy;
    expect(find.text('Item 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Item 14', skipOffstage: false));
    await tester.pump();
    expect(find.text('Item 1'), findsNothing);

    expect(
      tester.getTopLeft(find.byType(TabBarView)).dy,
      lessThan(initialAppBarHeight),
    );
  });

  testWidgets(
    'Does not crash when scrolling an inner list then switching tabs on desktop',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/183199
      //
      // Without the ScrollConfiguration in this example, the default desktop
      // scrollbar attaches to the NestedScrollView's coordinated controller and
      // throws once more than one ScrollPosition is attached to it, which happens
      // mid tab transition.
      await tester.pumpWidget(const example.NestedScrollViewExampleApp());
      await tester.pumpAndSettle();

      // The example opts out of the default scrollbars for its body.
      expect(find.byType(Scrollbar), findsNothing);

      // Scroll the first tab's inner list.
      await tester.drag(
        find.text('Item 0'),
        const Offset(0.0, -100.0),
        touchSlopY: 0.0,
      );
      await tester.pump();

      // Begin, but do not finish, a tab transition so both tabs' inner scroll
      // views are attached to the coordinated controller at the same time.
      await tester.fling(
        find.byType(TabBarView),
        const Offset(-300.0, 0.0),
        800.0,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // A mouse-wheel pointer signal mid-transition previously drove the
      // scrollbar validation while more than one position was attached.
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      final Offset center = tester.getCenter(find.byType(TabBarView));
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 60.0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.desktop(),
  );
}
