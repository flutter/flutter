// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

      // Find the first item and its drag handle
      final Finder item0 = find.byKey(const ValueKey<String>('Item 0'));
      final Finder textItem0 = find.byKey(const Key('text_Item 0'));
      final Finder dragHandle = find.descendant(
        of: item0,
        matching: find.byKey(const Key('drag_handle')),
      );
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      // Get initial position of the text (not the drag handle)
      final Offset initialTextCenter = tester.getCenter(textItem0);
      final double initialY = initialTextCenter.dy;
      print('Initial position of Item 0: y=$initialY');
      
      // Start the drag gesture from the drag handle
      final Offset dragHandleCenter = tester.getCenter(dragHandle);
      final TestGesture gesture = await tester.startGesture(dragHandleCenter);
      print('Started drag from handle at position y=${dragHandleCenter.dy}');
      
      // Small pause to ensure drag is registered
      await tester.pump(const Duration(milliseconds: 50));
      
      // Drag down 150px (past the second item completely)
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump(const Duration(milliseconds: 300)); // Let the drag register and settle
      
      // Get position after dragging down
      final Offset afterDragDown = tester.getCenter(textItem0);
      print('Position after dragging down 150px: y=${afterDragDown.dy}');
      
      // Hold at this position for a moment
      await tester.pump(const Duration(milliseconds: 500));
      print('Holding at down position...');
      
      // Drag back up to almost the original position (10px offset)
      await gesture.moveBy(const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 300)); // Let the drag register and settle
      
      // Get position after dragging back up
      final Offset afterDragUp = tester.getCenter(textItem0);
      print('Position after dragging back to original: y=${afterDragUp.dy}');
      print('Relative to initial position: y=${afterDragUp.dy - initialY}');
      
      // Check the order of items while still dragging
      print('\nChecking item order while dragging at y=25:');
      final Finder item1 = find.byKey(const ValueKey<String>('Item 1'));
      final Offset item0Pos = tester.getCenter(textItem0);
      final Offset item1Pos = tester.getCenter(find.byKey(const Key('text_Item 1')));
      print('Item 0 position: y=${item0Pos.dy}');
      print('Item 1 position: y=${item1Pos.dy}');
      
      if (item0Pos.dy < item1Pos.dy) {
        print('Order: Item 0 is above Item 1 (correct)');
      } else {
        print('Order: Item 0 is below Item 1 (items have swapped!)');
      }
      
      // Hold at this position before releasing
      await tester.pump(const Duration(milliseconds: 500));
      print('Holding at up position before release...');
      
      // Release the drag
      await gesture.up();
      print('Released drag');
      
      // Now capture the animation positions over a longer period
      final List<double> animationPositions = <double>[];
      const Duration animationCheckDuration = Duration(milliseconds: 500); // Longer duration to see settling
      const Duration checkInterval = Duration(milliseconds: 10);
      
      // Capture positions during animation
      final DateTime startTime = DateTime.now();
      double? settlePosition;
      double? previousPosition;
      
      while (DateTime.now().difference(startTime) < animationCheckDuration) {
        await tester.pump(checkInterval);
        
        try {
          // Try to find the proxy or the item during animation
          final Offset currentPosition = tester.getCenter(textItem0);
          final double currentY = currentPosition.dy;
          animationPositions.add(currentY);
          
          final int elapsed = DateTime.now().difference(startTime).inMilliseconds;
          print('Animation position at ${elapsed}ms: y=$currentY');
          
          // Check if position has settled (stopped changing significantly)
          if (previousPosition != null && (currentY - previousPosition).abs() < 0.5 && settlePosition == null) {
            settlePosition = currentY;
            print('>>> Position settled at y=$settlePosition (elapsed: ${elapsed}ms)');
          }
          previousPosition = currentY;
        } catch (e) {
          // Item might not be found during certain animation frames
          print('Could not find item during animation at ${DateTime.now().difference(startTime).inMilliseconds}ms');
        }
      }
      
      // Allow animation to complete
      await tester.pumpAndSettle();
      
      // Get final position
      final Offset finalPosition = tester.getCenter(textItem0);
      print('Final position: y=${finalPosition.dy}');
      
      // Analyze the animation behavior
      if (animationPositions.length >= 2) {
        final double firstPosition = animationPositions.first;
        final double secondPosition = animationPositions[1];
        
        print('\nAnimation analysis:');
        print('Released at y=${afterDragUp.dy} (should return to y=$initialY)');
        print('First captured position: $firstPosition');
        print('Second captured position: $secondPosition');
        print('Initial direction: ${secondPosition > firstPosition ? "DOWNWARD" : "UPWARD"}');
        
        if (settlePosition != null) {
          print('\nSettling behavior:');
          print('Proxy settled at y=$settlePosition');
          print('Expected final position: y=$initialY');
          print('Settle offset from expected: ${settlePosition - initialY}');
          
          // Check if it settled at the wrong position
          if ((settlePosition - initialY).abs() > 5) {
            print('>>> BUG: Proxy settled ${settlePosition - initialY > 0 ? "BELOW" : "ABOVE"} the original position!');
          }
        }
        
        // With the bug: the proxy should animate DOWNWARD first and settle at wrong position
        // With the fix: the proxy should animate UPWARD to original position
        // Since we released at y=25 (above center), it should animate upward to return to original position
        
        // The bug would show downward movement first
        final bool movingDownward = secondPosition > firstPosition;
        
        // For this test to demonstrate the bug, we expect:
        // - Without fix: movingDownward = true (BUG - animates wrong direction)
        // - With fix: movingDownward = false (CORRECT - animates upward)
        
        // Print result for debugging
        print('\nTest result: Proxy initially moved ${movingDownward ? "DOWNWARD" : "UPWARD"}');
        print('This indicates the animation bug is ${movingDownward ? "PRESENT" : "FIXED"}');
        
        // Note: We're not asserting here because we want to see the behavior
        // on both branches. In a real test, you would assert based on expected behavior.
      } else {
        print('\nCould not capture enough animation positions to determine direction');
      }
      
      // Verify final state is correct (items should be in original order)
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      
      // Check that Item 0 is back at its original position
      final Offset item0FinalPosition = tester.getCenter(textItem0);
      expect(item0FinalPosition.dy, closeTo(initialY, 1.0), 
        reason: 'Item 0 should return to its original position');
    });
  });
}