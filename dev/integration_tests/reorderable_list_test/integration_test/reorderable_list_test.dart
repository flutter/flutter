// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test verifies the fix for https://github.com/flutter/flutter/issues/88331
//
// Bug: When dragging a ReorderableListView item away from its original position
// and then back to that position, the proxy (dragged item) animates in the wrong
// direction - downward instead of upward - before settling at the original position.
//
// This test drags an item down 150px, then back up 140px (ending 10px below its
// original position). Upon release, the proxy should animate upward to settle at
// the original position. With the bug present, it animates downward first.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ReorderableList animation bug test', () {
    testWidgets('proxy animates in correct direction when dragged back to original position', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the item and its drag handle
      final Finder textItem0 = find.byKey(const Key('text_Item 0'));
      final Finder dragHandle = find.byKey(const Key('drag_handle_0'));
      
      // Verify we found the drag handle
      expect(dragHandle, findsOneWidget, reason: 'Should find drag handle for Item 0');
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      // Get initial positions of both items
      final double initialY = tester.getCenter(textItem0).dy;
      final double item1InitialY = tester.getCenter(find.byKey(const Key('text_Item 1'))).dy;
      
      // Start drag gesture
      final TestGesture gesture = await tester.startGesture(tester.getCenter(dragHandle));
      
      // Animate drag down 150px with ease-in-out curve over 300ms
      const int steps = 20;
      const Duration stepDuration = Duration(milliseconds: 15);
      
      for (int i = 1; i <= steps; i++) {
        // Use ease-in-out curve for smooth motion
        final double t = i / steps;
        final double easedT = Curves.easeInOut.transform(t);
        final double targetY = 150 * easedT;
        final double deltaY = targetY - (150 * Curves.easeInOut.transform((i - 1) / steps));
        
        await gesture.moveBy(Offset(0, deltaY));
        await tester.pump(stepDuration);
      }
      
      // Verify Item 1 position to ensure we're dragging, not scrolling
      final double item1AfterDrag = tester.getCenter(find.byKey(const Key('text_Item 1'))).dy;
      
      // Check if both items moved by the same amount (indicates scrolling, not dragging)
      final double item0Movement = tester.getCenter(textItem0).dy - initialY;
      final double item1Movement = item1AfterDrag - item1InitialY;
      
      if ((item1Movement - item0Movement).abs() < 5) {
        fail('Test failed: Both items moved by ~${item0Movement}px. This indicates the list was scrolled instead of Item 0 being dragged. The drag gesture was not properly initiated.');
      }
      
      // Animate drag back up 140px with ease-in-out curve over 300ms
      
      for (int i = 1; i <= steps; i++) {
        // Use ease-in-out curve for smooth motion
        final double t = i / steps;
        final double easedT = Curves.easeInOut.transform(t);
        final double targetY = -140 * easedT;
        final double deltaY = targetY - (-140 * Curves.easeInOut.transform((i - 1) / steps));
        
        await gesture.moveBy(Offset(0, deltaY));
        await tester.pump(stepDuration);
      }
      
      // Pause for 100ms to make the transition less chaotic
      await tester.pump(const Duration(milliseconds: 100));
      
      // Release the drag
      await gesture.up();
      
      // Capture the first few animation positions to detect direction
      final List<double> animationPositions = <double>[];
      
      // Capture initial positions during animation
      for (int i = 0; i < 30; i++) { // 300ms total
        await tester.pump(const Duration(milliseconds: 10));
        try {
          final double currentY = tester.getCenter(textItem0).dy;
          animationPositions.add(currentY);
        } catch (e) {
          // Item might not be found during certain animation frames
        }
      }
      
      // Analyze the animation behavior
      expect(animationPositions.length, greaterThanOrEqualTo(2),
        reason: 'Should capture at least 2 animation positions');
      
      final double firstPosition = animationPositions.first;
      final double secondPosition = animationPositions[1];
      
      // The bug causes the proxy to animate downward first when returning to original position
      final bool movingDownward = secondPosition > firstPosition;
      
      // The proxy should animate upward to return to its original position
      expect(movingDownward, isFalse,
        reason: 'Bug #88331: Proxy animated downward instead of upward when returning to original position');
      
      // Allow animation to complete and verify final state
      await tester.pumpAndSettle();
      
      // Verify items are in original order and position
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(tester.getCenter(textItem0).dy, closeTo(initialY, 1.0), 
        reason: 'Item 0 should return to its original position');
    });
  });
}