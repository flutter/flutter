// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'debug.dart';
import 'object.dart';
import 'sliver.dart';

/// Inset a [RenderSliver], applying padding on each side.
///
/// A [RenderSliverPadding] object wraps the [SliverGeometry.layoutExtent] of
/// its child. Any incoming [SliverConstraints.overlap] is ignored and not
/// passed on to the child.
///
/// Applying padding to anything but the most mundane sliver is likely to have
/// undesired effects. For example, wrapping a
/// [RenderSliverPinnedPersistentHeader] will cause the app bar to overlap
/// earlier slivers (contrary to the normal behavior of pinned app bars), and
/// while the app bar is pinned, the padding will scroll away.
class RenderSliverPadding extends RenderSliver with RenderObjectWithChildMixin<RenderSliver> {
  /// Creates a render object that insets its child in a viewport.
  ///
  /// The [padding] argument must not be null and must have non-negative insets.
  RenderSliverPadding({
    @required EdgeInsets padding,
    RenderSliver child,
  }) : _padding = padding {
    assert(padding != null);
    assert(padding.isNonNegative);
    this.child = child;
  }

  /// The amount to pad the child in each dimension.
  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    assert(value != null);
    assert(value.isNonNegative);
    if (_padding == value)
      return;
    _padding = value;
    markNeedsLayout();
  }

  /// The padding in the scroll direction on the side nearest the 0.0 scroll direction.
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get beforePadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return padding.bottom;
      case AxisDirection.right:
        return padding.left;
      case AxisDirection.down:
        return padding.top;
      case AxisDirection.left:
        return padding.right;
    }
    return null;
  }

  /// The padding in the scroll direction on the side furthest from the 0.0 scroll offset.
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get afterPadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return padding.top;
      case AxisDirection.right:
        return padding.right;
      case AxisDirection.down:
        return padding.bottom;
      case AxisDirection.left:
        return padding.left;
    }
    return null;
  }

  /// The total padding in the [SliverConstraints.axisDirection]. (In other
  /// words, for a vertical downwards-growing list, the sum of the padding on
  /// the top and bottom.)
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get mainAxisPadding {
    assert(constraints != null);
    assert(constraints.axis != null);
    return padding.along(constraints.axis);
  }

  /// The total padding in the cross-axis direction. (In other words, for a
  /// vertical downwards-growing list, the sum of the padding on the left and
  /// right.)
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get crossAxisPadding {
    assert(constraints != null);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        return padding.vertical;
      case Axis.vertical:
        return padding.horizontal;
    }
    return null;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = new SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    final double beforePadding = this.beforePadding;
    final double afterPadding = this.afterPadding;
    final double mainAxisPadding = this.mainAxisPadding;
    final double crossAxisPadding = this.crossAxisPadding;
    if (child == null) {
      geometry = new SliverGeometry(
        scrollExtent: mainAxisPadding,
        paintExtent: math.min(mainAxisPadding, constraints.remainingPaintExtent),
        maxPaintExtent: mainAxisPadding,
      );
      return;
    }
    child.layout(
      constraints.copyWith(
        scrollOffset: math.max(0.0, constraints.scrollOffset - beforePadding),
        overlap: 0.0,
        remainingPaintExtent: constraints.remainingPaintExtent - calculatePaintOffset(constraints, from: 0.0, to: beforePadding),
        crossAxisExtent: constraints.crossAxisExtent - crossAxisPadding,
      ),
      parentUsesSize: true,
    );
    final SliverGeometry childLayoutGeometry = child.geometry;
    final double beforePaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: beforePadding,
    );
    final double afterPaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: beforePadding + childLayoutGeometry.scrollExtent,
      to: mainAxisPadding + childLayoutGeometry.scrollExtent,
    );
    final double mainAxisPaddingPaintExtent = beforePaddingPaintExtent + afterPaddingPaintExtent;
    final double paintExtent = math.min(
      beforePaddingPaintExtent + math.max(childLayoutGeometry.paintExtent, childLayoutGeometry.layoutExtent + afterPaddingPaintExtent),
      constraints.remainingPaintExtent,
    );
    geometry = new SliverGeometry(
      scrollExtent: mainAxisPadding + childLayoutGeometry.scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: math.min(mainAxisPaddingPaintExtent + childLayoutGeometry.layoutExtent, paintExtent),
      maxPaintExtent: mainAxisPadding + childLayoutGeometry.maxPaintExtent,
      hitTestExtent: math.max(
        mainAxisPaddingPaintExtent + childLayoutGeometry.paintExtent,
        beforePaddingPaintExtent + childLayoutGeometry.hitTestExtent,
      ),
      hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
    );

    final SliverPhysicalParentData childParentData = child.parentData;
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        childParentData.paintOffset = new Offset(padding.left, calculatePaintOffset(constraints, from: padding.bottom + childLayoutGeometry.scrollExtent, to: padding.bottom + childLayoutGeometry.scrollExtent + padding.top));
        break;
      case AxisDirection.right:
        childParentData.paintOffset = new Offset(calculatePaintOffset(constraints, from: 0.0, to: padding.left), padding.top);
        break;
      case AxisDirection.down:
        childParentData.paintOffset = new Offset(padding.left, calculatePaintOffset(constraints, from: 0.0, to: padding.top));
        break;
      case AxisDirection.left:
        childParentData.paintOffset = new Offset(calculatePaintOffset(constraints, from: padding.right + childLayoutGeometry.scrollExtent, to: padding.right + childLayoutGeometry.scrollExtent + padding.left), padding.top);
        break;
    }
    assert(childParentData.paintOffset != null);
    assert(beforePadding == this.beforePadding);
    assert(afterPadding == this.afterPadding);
    assert(mainAxisPadding == this.mainAxisPadding);
    assert(crossAxisPadding == this.crossAxisPadding);
  }

  @override
  bool hitTestChildren(HitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
    if (child.geometry.hitTestExtent > 0.0)
      return child.hitTest(result, mainAxisPosition: mainAxisPosition - childMainAxisPosition(child), crossAxisPosition: crossAxisPosition - childCrossAxisPosition(child));
    return false;
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    assert(child != null);
    assert(child == this.child);
    return calculatePaintOffset(constraints, from: 0.0, to: beforePadding);
  }

  @override
  double childCrossAxisPosition(RenderSliver child) {
    assert(child != null);
    assert(child == this.child);
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
      case AxisDirection.down:
        return padding.left;
      case AxisDirection.left:
      case AxisDirection.right:
        return padding.top;
    }
    return null;
  }

  @override
  double childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    return beforePadding;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child.geometry.visible) {
      final SliverPhysicalParentData childParentData = child.parentData;
      context.paintChild(child, offset + childParentData.paintOffset);
    }
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    super.debugPaint(context, offset);
    assert(() {
      if (debugPaintSizeEnabled) {
        final Size parentSize = getAbsoluteSizeRelativeToOrigin();
        final Rect outerRect = offset & parentSize;
        Size childSize;
        Rect innerRect;
        if (child != null) {
          childSize = child.getAbsoluteSizeRelativeToOrigin();
          final SliverPhysicalParentData childParentData = child.parentData;
          innerRect = (offset + childParentData.paintOffset) & childSize;
          assert(innerRect.top >= outerRect.top);
          assert(innerRect.left >= outerRect.left);
          assert(innerRect.right <= outerRect.right);
          assert(innerRect.bottom <= outerRect.bottom);
        }
        debugPaintPadding(context.canvas, outerRect, innerRect);
      }
      return true;
    });
  }
}
