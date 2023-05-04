// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;
import 'package:flutter_test/flutter_test.dart';

Widget buildSimpleTest({
  Axis mainAxis = Axis.vertical,
  bool? primary,
  ScrollableDetails? verticalDetails,
  ScrollableDetails? horizontalDetails,
  TwoDimensionalChildDelegate? delegate,
  double? cacheExtent,
  DiagonalDragBehavior? diagonalDrag,
  Clip? clipBehavior,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SimpleTableView(
        mainAxis: mainAxis,
        verticalDetails: verticalDetails ?? const ScrollableDetails.vertical(),
        horizontalDetails: horizontalDetails ?? const ScrollableDetails.horizontal(),
        cacheExtent: cacheExtent,
        diagonalDragBehavior: diagonalDrag ?? DiagonalDragBehavior.none,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        delegate: delegate ?? TwoDimensionalChildBuilderDelegate(
          maxXIndex: 99,
          maxYIndex: 99,
          builder: (BuildContext context, ChildVicinity vicinity) {
            return Container(
              color: vicinity.xIndex.isEven && vicinity.yIndex.isEven
                ? Colors.amber[100]
                : (vicinity.xIndex.isOdd && vicinity.yIndex.isOdd
                  ? Colors.blueAccent[100]
                  : null),
              height: 200,
              width: 200,
              child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
            );
          }
        ),
      ),
    ),
  );
}

class SimpleTableView extends TwoDimensionalScrollView {
  const SimpleTableView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required super.delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset, ViewportOffset horizontalOffset) {
    return SimpleTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class SimpleTableViewport extends TwoDimensionalViewport {
  const SimpleTableViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderSimpleTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSimpleTableViewport renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderSimpleTableViewport extends RenderTwoDimensionalViewport {
  RenderSimpleTableViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    this.applyDimensions = true,
    this.useParentSize = true,
    this.setLayoutOffset = true,
  });

  final bool applyDimensions; // Testing error message
  final bool useParentSize; // Testing error message
  final bool setLayoutOffset; // Testing error message

  @override
  void layoutChildSequence() {
    // Really simple table implementation for testing.
    // Every child is 200x200 square
    final double horizontalPixels = horizontalOffset.pixels;
    final double verticalPixels = verticalOffset.pixels;
    final int leadingColumn = math.max((horizontalPixels / 200).floor(), 0);
    final int leadingRow = math.max((verticalPixels / 200).floor(), 0);
    final int trailingColumn = math.min(((horizontalPixels + viewportDimension.width) / 200).ceil(), 99);
    final int trailingRow = math.min(((verticalPixels + viewportDimension.height) / 200).ceil(), 99);

    double xLayoutOffset = (leadingColumn * 200) - horizontalOffset.pixels;
    for(int column = leadingColumn; column <= trailingColumn; column++) {
      double yLayoutOffset =  (leadingRow * 200) - verticalOffset.pixels;
      for (int row = leadingRow; row <= trailingRow; row++) {
        final ChildVicinity vicinity = ChildVicinity(xIndex: row, yIndex: column);
        final RenderBox child = buildOrObtainChildFor(vicinity)!;
        child.layout(
          constraints.tighten(width: 200.0, height: 200.0),
          parentUsesSize: useParentSize,
        );

        if (setLayoutOffset) {
          parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);
        }
        yLayoutOffset += 200;
      }
      xLayoutOffset += 200;
    }
    if (applyDimensions) {
      verticalOffset.applyContentDimensions(0, 200 * 100 - viewportDimension.height);
      horizontalOffset.applyContentDimensions(0, 200 * 100 - viewportDimension.width);
    }
  }
}

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
