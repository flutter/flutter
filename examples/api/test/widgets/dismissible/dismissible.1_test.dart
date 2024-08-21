// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/dismissible/dismissible.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> initWidget(WidgetTester tester) async {
    await tester.pumpWidget(const example.DismissibleExampleApp());
  }

  Future<void> reset(WidgetTester tester) async {
    final Finder fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();
  }

  Future<void> dismissHorizontally({
    required WidgetTester tester,
    required Finder finder,
    double dragRatio = 0.8,
    AxisDirection direction = AxisDirection.left,
  }) async {
    final double width = (tester.renderObject(finder) as RenderBox).size.width;
    final double dx = width * dragRatio;

    final Offset offset = switch (direction) {
      AxisDirection.left => Offset(-dx, 0.0),
      AxisDirection.right => Offset(dx, 0.0),
      _ => throw ArgumentError('$direction is not supported'),
    };

    await tester.drag(finder, offset);
  }

  Future<void> testDragBehavior(
    WidgetTester tester, {
    required Key key,
    Matcher expectedBelowThreshold = findsOneWidget,
    Matcher expectedAboveThreshold = findsNothing,
  }) async {
    await tester.scrollUntilVisible(find.byKey(key), 100);

    expect(find.byKey(key), findsOneWidget);

    // Drag below the threshold
    await dismissHorizontally(
      tester: tester,
      finder: find.byKey(key),
      dragRatio: 0.3,
    );

    await tester.pumpAndSettle();

    expect(find.byKey(key), expectedBelowThreshold);

    await reset(tester);

    // Drag above the threshold
    await dismissHorizontally(
      tester: tester,
      finder: find.byKey(key),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(key), expectedAboveThreshold);
  }

  group('Test Drag behavior', () {
    testWidgets(
      '0 - Default begavior - `shouldTriggerDismiss: null`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(0);
        await testDragBehavior(tester, key: key);
      },
    );

    testWidgets(
      '1 - Default begavior - `shouldTriggerDismiss: (_) => null`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(1);
        await testDragBehavior(tester, key: key);
      },
    );

    testWidgets(
      '2 - Never dismiss - `shouldTriggerDismiss: (_) => false`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(2);
        await testDragBehavior(
          tester,
          key: key,
          expectedAboveThreshold: findsOneWidget,
        );
      },
    );

    testWidgets(
      '3 - Always dismiss - `shouldTriggerDismiss: (_) => true`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(3);
        await testDragBehavior(
          tester,
          key: key,
          expectedBelowThreshold: findsNothing,
        );
      },
    );

    testWidgets(
      '4 - Only accept if threshold is reached (Disable flinging)',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(4);
        await testDragBehavior(tester, key: key);
      },
    );

    testWidgets(
      '5 - Accept dismiss before threshold - `details.progress >= 0.2`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(5);
        await testDragBehavior(
          tester,
          key: key,
          expectedBelowThreshold: findsNothing,
        );
      },
    );
  });

  Future<void> flingHorizontally({
    required WidgetTester tester,
    required Finder finder,
    double speed = 1000,
    AxisDirection direction = AxisDirection.left,
  }) async {
    final double width = (tester.renderObject(finder) as RenderBox).size.width;
    final double dx = width * 0.1;

    final Offset offset = switch (direction) {
      AxisDirection.left => Offset(-dx, 0.0),
      AxisDirection.right => Offset(dx, 0.0),
      _ => throw ArgumentError('$direction is not supported'),
    };

    await tester.fling(finder, offset, speed);
  }

  Future<void> testFlingBehavior(
    WidgetTester tester, {
    required Key key,
    Matcher expectedBelowThreshold = findsOneWidget,
    Matcher expectedAboveThreshold = findsNothing,
  }) async {
    await tester.scrollUntilVisible(find.byKey(key), 100);

    expect(find.byKey(key), findsOneWidget);

    // Fling below fling velocity threshold
    await flingHorizontally(
      tester: tester,
      finder: find.byKey(key),
      speed: 200,
    );

    await tester.pumpAndSettle();

    expect(find.byKey(key), expectedBelowThreshold);

    await reset(tester);

    // Fling above fling velocity threshold
    await flingHorizontally(
      tester: tester,
      finder: find.byKey(key),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(key), expectedAboveThreshold);
  }

  group('Test Fling behavior', () {
    testWidgets(
      '0 - Default begavior - `shouldTriggerDismiss: null`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(0);
        await testFlingBehavior(tester, key: key);
      },
    );

    testWidgets(
      '1 - Default begavior - `shouldTriggerDismiss: (_) => null`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(1);
        await testFlingBehavior(tester, key: key);
      },
    );

    testWidgets(
      '2 - Never dismiss - `shouldTriggerDismiss: (_) => false`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(2);
        await testFlingBehavior(
          tester,
          key: key,
          expectedAboveThreshold: findsOneWidget,
        );
      },
    );

    testWidgets(
      '3 - Always dismiss - `shouldTriggerDismiss: (_) => true`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(3);
        await testFlingBehavior(
          tester,
          key: key,
          expectedBelowThreshold: findsNothing,
        );
      },
    );

    testWidgets(
      '4 - Only accept if threshold is reached (Disable flinging)',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(4);
        await testFlingBehavior(
          tester,
          key: key,
          expectedAboveThreshold: findsOneWidget,
        );
      },
    );

    testWidgets(
      '5 - Accept dismiss before threshold - `details.progress >= 0.2`',
      (WidgetTester tester) async {
        await initWidget(tester);

        const ValueKey<int> key = ValueKey<int>(5);
        await testFlingBehavior(tester, key: key);
      },
    );
  });
}
