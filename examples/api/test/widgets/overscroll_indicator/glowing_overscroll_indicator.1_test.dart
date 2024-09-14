// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/overscroll_indicator/glowing_overscroll_indicator.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test visibility', (WidgetTester tester) async {
    await tester.pumpWidget(const example.GlowingOverscrollIndicatorExampleApp());

    expect(find.descendant(
      of: find.byType(Scaffold),
      matching: find.widgetWithText(AppBar, 'GlowingOverscrollIndicator Sample'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(NestedScrollView),
      matching: find.widgetWithText(SliverAppBar, 'Custom NestedScrollViews'),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(NestedScrollView),
      matching: find.widgetWithText(Center, 'Glow all day!'),
    ), findsOne);

   expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(SliverToBoxAdapter),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(SliverFillRemaining),
    ), findsOne);

    expect(find.descendant(
      of: find.byType(SliverFillRemaining),
      matching: find.byType(FlutterLogo),
    ), findsOne);

  });
  testWidgets('Test behaviour', (WidgetTester tester) async {
    bool overscrollNotified = false;

    // custom listener
    await tester.pumpWidget(
      NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification notification) {
          overscrollNotified = true;
          return false;
        },
        child: const example.GlowingOverscrollIndicatorExampleApp(),
      ),
    );

    expect(overscrollNotified, isFalse);

    final Finder customScrollViewFinder = find.byType(CustomScrollView);
    await tester.drag(customScrollViewFinder, const Offset(0.0, 500));
    await tester.pump();

    expect(overscrollNotified, isTrue);
  });
}
