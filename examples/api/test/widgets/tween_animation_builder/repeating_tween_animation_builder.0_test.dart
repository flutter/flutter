// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/tween_animation_builder/repeating_tween_animation_builder.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RepeatingTweenAnimationBuilder continuously animates', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RepeatingTweenAnimationBuilderExampleApp());

    // Find the container which is being rotated
    final Finder containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);

    // Find the Transform widget that wraps the container
    final Finder transformFinder = find.ancestor(
      of: containerFinder,
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsOneWidget);

    // The animation should continuously repeat
    // Let's verify it animates through multiple cycles
    final List<Matrix4> transforms = <Matrix4>[];

    // Capture initial transform
    Transform transform = tester.widget(transformFinder);
    transforms.add(transform.transform);

    // Advance through animation cycles
    const Duration animationDuration = Duration(seconds: 2);
    for (int i = 0; i < 5; i++) {
      await tester.pump(animationDuration ~/ 4);
      transform = tester.widget(transformFinder);
      transforms.add(transform.transform);
    }

    // Verify that the transforms are different (animation is happening)
    expect(transforms.toSet().length, greaterThan(1));
  });

  testWidgets('Pause and resume buttons control animation', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RepeatingTweenAnimationBuilderExampleApp());

    final Finder transformFinder = find.byType(Transform).first;

    // Let animation run
    await tester.pump(const Duration(milliseconds: 100));

    // Get transform before pause
    final Transform transformBeforePause = tester.widget(transformFinder);
    final Matrix4 beforePause = transformBeforePause.transform;

    // Tap pause button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pause'));
    await tester.pump();

    // Verify button text changed to "Resume"
    expect(find.widgetWithText(ElevatedButton, 'Resume'), findsOneWidget);

    // Pump time and verify animation is paused (transform stays the same)
    await tester.pump(const Duration(milliseconds: 200));
    final Transform transformWhilePaused = tester.widget(transformFinder);
    expect(transformWhilePaused.transform, equals(beforePause));

    // Resume the animation
    await tester.tap(find.widgetWithText(ElevatedButton, 'Resume'));
    await tester.pump();

    // Verify button text changed back to "Pause"
    expect(find.widgetWithText(ElevatedButton, 'Pause'), findsOneWidget);

    // Let animation run and verify it resumed (transform changed)
    await tester.pump(const Duration(milliseconds: 200));
    final Transform transformAfterResume = tester.widget(transformFinder);
    expect(transformAfterResume.transform, isNot(equals(beforePause)));
  });

  testWidgets('Reverse button toggles animation direction', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RepeatingTweenAnimationBuilderExampleApp());

    // Initially shows "Reverse" button
    expect(find.widgetWithText(ElevatedButton, 'Reverse'), findsOneWidget);

    // Tap to enable reverse mode
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reverse'));
    await tester.pump();

    // Verify button text changed to "Forward Only"
    expect(find.widgetWithText(ElevatedButton, 'Forward Only'), findsOneWidget);

    // Toggle back to forward-only mode
    await tester.tap(find.widgetWithText(ElevatedButton, 'Forward Only'));
    await tester.pump();

    // Verify button text changed back to "Reverse"
    expect(find.widgetWithText(ElevatedButton, 'Reverse'), findsOneWidget);
  });
}
