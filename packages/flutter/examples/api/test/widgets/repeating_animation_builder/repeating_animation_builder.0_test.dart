// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/repeating_animation_builder/repeating_animation_builder.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RepeatingAnimationBuilder animates continuously', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.RepeatingAnimationBuilderExampleApp(),
    );

    // Verify animation is happening by checking Transform changes
    final Transform initial = tester.widget(find.byType(Transform).first);
    await tester.pump(const Duration(milliseconds: 500));
    final Transform after = tester.widget(find.byType(Transform).first);

    expect(initial.transform, isNot(equals(after.transform)));
  });

  testWidgets('Play/pause button controls animation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.RepeatingAnimationBuilderExampleApp(),
    );

    // Initially playing (pause icon visible)
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Tap to pause
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Verify animation stopped
    final Transform paused = tester.widget(find.byType(Transform).first);
    await tester.pump(const Duration(milliseconds: 500));
    final Transform stillPaused = tester.widget(find.byType(Transform).first);
    expect(paused.transform, equals(stillPaused.transform));

    // Resume animation
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('Reverse toggle changes animation direction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const example.RepeatingAnimationBuilderExampleApp(),
    );

    // Check initial state
    Switch switchWidget = tester.widget(find.byType(Switch));
    expect(switchWidget.value, false);

    // Toggle reverse
    await tester.tap(find.byType(Switch));
    await tester.pump();

    // Verify toggled
    switchWidget = tester.widget(find.byType(Switch));
    expect(switchWidget.value, true);
  });
}
