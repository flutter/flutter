// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

void main() {
  group('ZoomControls', () {
    late TransformationController controller;

    setUp(() {
      controller = TransformationController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('displays initial state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(transformationController: controller),
          ),
        ),
      );

      expect(find.byTooltip('Zoom in'), findsOneWidget);
      expect(find.byTooltip('Zoom out'), findsOneWidget);
      expect(find.byTooltip('Reset zoom'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Initially Zoom out and Reset are disabled, so they shouldn't respond to taps
      // We can verify they are disabled by checking that scale remains 1.0
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(controller.value.entry(0, 0), equals(1.0));

      await tester.tap(find.byTooltip('Reset zoom'));
      await tester.pump();
      expect(controller.value.entry(0, 0), equals(1.0));
    });

    testWidgets('Zoom in and Zoom out linearly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(transformationController: controller),
          ),
        ),
      );

      // Zoom in
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.25));
      expect(find.text('125%'), findsOneWidget);

      // Zoom in again
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.50));
      expect(find.text('150%'), findsOneWidget);

      // Zoom out
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.25));
      expect(find.text('125%'), findsOneWidget);

      // Zoom out to original scale
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.0));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('Reset zoom works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(transformationController: controller),
          ),
        ),
      );

      // Zoom in twice
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.5));

      // Reset
      await tester.tap(find.byTooltip('Reset zoom'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), equals(1.0));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('Slider updates scale correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(transformationController: controller),
          ),
        ),
      );

      final Slider slider = tester.widget(find.byType(Slider));
      expect(slider.value, equals(1.0));

      // Drag or set scale directly to test responsiveness
      controller.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      await tester.pumpAndSettle();

      expect(find.text('250%'), findsOneWidget);
      final Slider updatedSlider = tester.widget(find.byType(Slider));
      expect(updatedSlider.value, equals(2.5));
    });
  });

  group('ZoomablePreviewArea', () {
    late TransformationController controller;

    setUp(() {
      controller = TransformationController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders scaled layout wrapper when no tree construction error', (
      WidgetTester tester,
    ) async {
      const childKey = Key('preview_child');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomablePreviewArea(
              transformationController: controller,
              errorThrownDuringTreeConstruction: false,
              child: const SizedBox(key: childKey, width: 100, height: 100),
            ),
          ),
        ),
      );

      // Scaling is applied, so we should find the child and verify it builds within _ScaledLayoutWrapper
      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNWidgets(2));
    });

    testWidgets(
      'renders unscaled child directly when tree construction error occurred',
      (WidgetTester tester) async {
        const childKey = Key('error_child');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ZoomablePreviewArea(
                transformationController: controller,
                errorThrownDuringTreeConstruction: true,
                child: const SizedBox(key: childKey, width: 100, height: 100),
              ),
            ),
          ),
        );

        expect(find.byKey(childKey), findsOneWidget);
        // It shouldn't be wrapped inside SingleChildScrollView or any scaling logic
        expect(find.byType(SingleChildScrollView), findsNothing);
      },
    );
  });
}
