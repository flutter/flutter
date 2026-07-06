// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/composited_transform/composited_transform_follower.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows target and follower', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CompositedTransformFollowerExampleApp(),
    );

    expect(find.text('Press me'), findsOneWidget);
    expect(find.byType(CompositedTransformTarget), findsOneWidget);

    // Overlay is not shown until the target is pressed.
    expect(find.byType(CompositedTransformFollower), findsNothing);
    expect(find.text('Hello from the overlay!'), findsNothing);

    await tester.tap(find.text('Press me'));
    await tester.pump();

    expect(find.byType(CompositedTransformFollower), findsOneWidget);
    expect(find.text('Hello from the overlay!'), findsOneWidget);

    final Rect targetRect = tester.getRect(
      find.byType(CompositedTransformTarget),
    );
    final Rect followerRect = tester.getRect(
      find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(followerRect.topCenter, targetRect.bottomCenter);
  });

  testWidgets('Tapping target again hides the follower', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.CompositedTransformFollowerExampleApp(),
    );

    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(find.text('Hello from the overlay!'), findsOneWidget);

    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(find.text('Hello from the overlay!'), findsNothing);
  });
}
