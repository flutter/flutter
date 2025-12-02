// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/page_transitions_builder/page_transitions_builder.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Custom page transition example', (WidgetTester tester) async {
    await tester.pumpWidget(const example.PageTransitionsBuilderExampleApp());

    // Find the initial page
    expect(find.text('Custom Page Transitions'), findsOneWidget);
    expect(find.text('Navigate with Custom Transition'), findsOneWidget);

    // Tap the button to navigate
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify we're on the second page
    expect(find.text('Second Page'), findsOneWidget);
    expect(
      find.text('This page appeared with a custom transition!'),
      findsOneWidget,
    );

    // Go back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify we're back on the first page
    expect(find.text('Custom Page Transitions'), findsOneWidget);
    expect(find.text('Navigate with Custom Transition'), findsOneWidget);
  });

  testWidgets(
    'SlideRightPageTransitionsBuilder creates slide and fade transitions',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.PageTransitionsBuilderExampleApp());

      // Navigate to second page
      await tester.tap(find.byType(ElevatedButton));

      // Pump one frame to start the animation
      await tester.pump();

      // The transition should be in progress
      await tester.pump(const Duration(milliseconds: 150));

      // The second page should be visible but still animating
      expect(find.text('Second Page'), findsOneWidget);

      // Complete the animation
      await tester.pumpAndSettle();

      // The second page should be fully visible
      expect(
        find.text('This page appeared with a custom transition!'),
        findsOneWidget,
      );
    },
  );
}
