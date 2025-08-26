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

    // Find the Transform widget that rotates - there should be at least one
    final Finder transformFinder = find.byType(Transform);
    expect(transformFinder, findsWidgets);

    // The animation should continuously repeat
    // Let's verify it animates through multiple cycles
    final List<Matrix4> transforms = <Matrix4>[];

    // Get the first transform widget (the rotating one)
    final Transform firstTransform = tester.widget(transformFinder.first);
    transforms.add(firstTransform.transform);

    // Advance through animation cycles
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final Transform transform = tester.widget(transformFinder.first);
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

    // Find the InkWell play/pause button
    final Finder playPauseButton = find.byType(InkWell).first;
    expect(playPauseButton, findsOneWidget);

    // Tap pause button (find icon to verify state)
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(playPauseButton);
    await tester.pump();

    // Verify icon changed to play
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);

    // Pump time and verify animation is paused (transform stays the same)
    await tester.pump(const Duration(milliseconds: 200));
    final Transform transformWhilePaused = tester.widget(transformFinder);
    expect(transformWhilePaused.transform, equals(beforePause));

    // Resume the animation
    await tester.tap(playPauseButton);
    await tester.pump();

    // Verify icon changed back to pause
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    // Let animation run and verify it resumed (transform changed)
    await tester.pump(const Duration(milliseconds: 200));
    final Transform transformAfterResume = tester.widget(transformFinder);
    expect(transformAfterResume.transform, isNot(equals(beforePause)));
  });

  testWidgets('Reverse button toggles animation direction', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RepeatingTweenAnimationBuilderExampleApp());

    // Find the Switch widget for reverse toggle
    final Finder switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // Initially, reverse should be off
    Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, false);

    // Find the GestureDetector that wraps the reverse toggle
    final Finder reverseToggleFinder = find.byType(GestureDetector).last;

    // Tap to enable reverse mode
    await tester.tap(reverseToggleFinder);
    await tester.pump();

    // Verify switch is now on
    switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, true);

    // Toggle back to forward-only mode
    await tester.tap(reverseToggleFinder);
    await tester.pump();

    // Verify switch is off again
    switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, false);
  });
}
