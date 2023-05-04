// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoDimensionalChildDelegate', () {
    group('TwoDimensionalChildBuilderDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        // Default

        // None

      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null form build for exceeding maxXIndex and maxYIndex', (WidgetTester tester) async {
        // maxXIndex

        // maxYIndex

      }, variant: TargetPlatformVariant.all());

      testWidgets('throws an error when builder throws', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());
    });

    group('TwoDimensionalChildListDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        // Default

        // None

      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null for a ChildVicinity outside of list bounds', (WidgetTester tester) async {
        // Default

        // None

      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());
    });
  });

  group('TwoDimensionalScrollable', () {
    testWidgets('.of, .maybeOf', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('horizontal and vertical getters', (WidgetTester tester) async {
      // Assert if there is no state yet.

      // Gets state

    }, variant: TargetPlatformVariant.all());

    testWidgets('creates fallback ScrollControllers if not provided by ScrollableDetails', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the axis directions do not conflict with one another', (WidgetTester tester) async {
      // Horizontal mismatch

      // Vertical mismatch

    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly sets restorationIds', (WidgetTester tester) async {
      // with restorationID set

      // default restorationID

    }, variant: TargetPlatformVariant.all());

    testWidgets('Inner Scrollables receive the correct details from TwoDimensionalScrollable', (WidgetTester tester) async {
      // Default

      // Customized

    }, variant: TargetPlatformVariant.all());

    testWidgets('calls on the ScrollBehavior to build two scrollbars', (WidgetTester tester) async {
      // with restorationID set

      // default restorationID

    }, variant: TargetPlatformVariant.all());

    group('DiagonalDragBehavior', () {
      testWidgets('none (default)', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedEvent', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedContinuous', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('free', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());
    });
  });

  testWidgets('TwoDimensionalViewport asserts against axes mismatch', (WidgetTester tester) async {
    // Horizontal mismatch

    // Vertical mismatch
  });

  test('TwoDimensionalViewportParentData', () {
    // Default vicinity is invalid

    // isVisible cases

    // toString
  });

  test('ChildVicinity comparable', () {
    // ==

    // compareTo

    // hashCode

    // toString
  });

  group('RenderTwoDimensionalViewport', () {
    testWidgets('asserts against axes mismatch', (WidgetTester tester) async {
      // Horizontal mismatch

      // Vertical mismatch
    });

    testWidgets('getters', (WidgetTester tester) async {
      // clipBehavior

      // cacheExtent

      // isRepaintBoundary

      // sizedByParent

      // viewportDimension - also asserts hasSize

      // horizontalOffset

      // horizontalAxisDirection

      // verticalOffset

      // verticalAxisDirection

      // delegate

      // mainAxis
    }, variant: TargetPlatformVariant.all());

    testWidgets('childrenInPaintOrder correlates with mainAxis', (WidgetTester tester) async {
      // mainAxis is vertical

      // mainAxis is horizontal
    }, variant: TargetPlatformVariant.all());

    testWidgets('sets up parent data', (WidgetTester tester) async {
      // parent data is TwoDimensionalViewportParentData

      // parentDataOf method works

      // parentData is computed correctly - normal axes
      // - layoutOffset, paintOffset, paintExtent, isVisible, ChildVicinity

      // parentData is computed correctly - reverse axes
      // - vertical reverse, horizontal reverse, both reverse
    }, variant: TargetPlatformVariant.all());

    testWidgets('computeChildPaintExtent', (WidgetTester tester) async {
      // Full view
      // Scrolled into top
      // Scrolled into bottom
      // Scrolled into leading edge
      // Scrolled into trailing edge
      // Scrolled into top left corner
      // Scrolled into top right corner
      // Scrolled into bottom left corner
      // Scrolled into bottom right corner

      // Reversed, vertical, horizontal, both
    }, variant: TargetPlatformVariant.all());

    testWidgets('computeChildPaintOffset', (WidgetTester tester) async {
      // Normal axes

      // Reversed, vertical, horizontal, both
    }, variant: TargetPlatformVariant.all());

    testWidgets('debugDescribeChildren', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that both axes are bounded', (WidgetTester tester) async {
      // Compose unbounded

      // Call computeDryLayout with unbounded constraints
    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly resizes dimensions', (WidgetTester tester) async {
      // performResize

      // didResize
    }, variant: TargetPlatformVariant.all());

    testWidgets('needsDelegateRebuild', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('hitTestChildren', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('getChildFor', (WidgetTester tester) async {
      // returns child

      // returns null
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts vicinity is valid', (WidgetTester tester) async {
      // buildOrObtainChildFor

      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('buildOrObtainChild can return null', (WidgetTester tester) async {
      // buildOrObtainChildFor

      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the vicinity of the parent data is correct', (WidgetTester tester) async {
      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that content dimensions have been applied', (WidgetTester tester) async {
      // Vertical

      // Horizontal
    }, variant: TargetPlatformVariant.all());

    testWidgets('will not rebuild a child if it can be reused', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the layoutOffset has been set by the subclass', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the children have a size after layoutChildSequence', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the children have been laid out with parentUsesSize: true', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('does not support intrinsics', (WidgetTester tester) async {
      // computeMinIntrinsicWidth

      // computeMaxIntrinsicWidth

      // computeMinIntrinsicHeight

      // computeMaxIntrinsicHeight
    }, variant: TargetPlatformVariant.all());
  });
}
