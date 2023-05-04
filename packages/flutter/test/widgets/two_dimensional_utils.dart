// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;

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
