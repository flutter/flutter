// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'object.dart';
import 'sliver.dart';

/// Insets a [RenderSliver] by applying [resolvedPadding] on each side.
///
/// A [RenderSliverEdgeInsetsPadding] subclass wraps the [SliverGeometry.layoutExtent]
/// of its child. Any incoming [SliverConstraints.overlap] is ignored and not
/// passed on to the child.
///
/// {@template flutter.rendering.RenderSliverEdgeInsetsPadding}
/// Applying padding in the main extent of the viewport to slivers that have scroll effects is likely to have
/// undesired effects. For example, For example, wrapping a [SliverPersistentHeader] with
/// `pinned:true` will cause only the appbar to stay pinned while the padding will scroll away.
/// {@endtemplate}
abstract class RenderSliverEdgeInsetsPadding extends RenderSliver with RenderObjectWithChildMixin<RenderSliver> {
  /// The amount to pad the child in each dimension.
  ///
  /// The offsets are specified in terms of visual edges, left, top, right, and
  /// bottom. These values are not affected by the [TextDirection].
  ///
  /// Must not be null or contain negative values when [performLayout] is called.
  EdgeInsets? get resolvedPadding;

  /// The padding in the scroll direction on the side nearest the 0.0 scroll direction.
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get beforePadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    assert(resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return resolvedPadding!.bottom;
      case AxisDirection.right:
        return resolvedPadding!.left;
      case AxisDirection.down:
        return resolvedPadding!.top;
      case AxisDirection.left:
        return resolvedPadding!.right;
    }
  }

  /// The padding in the scroll direction on the side furthest from the 0.0 scroll offset.
  ///
  /// Only valid after layout has started, since before layout the render object
  /// doesn't know what direction it will be laid out in.
  double get afterPadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    assert(resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return resolvedPadding!.top;
      case AxisDirection.right:
        return resolvedPadding!.right;
      case AxisDirection.down:
        return resolvedPadding!.bottom;
      case AxisDirection.left:
        return resolvedPadding!.left;
    }
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
    assert(resolvedPadding != null);
    return resolvedPadding!.along(constraints.axis);
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
    assert(resolvedPadding != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        return resolvedPadding!.vertical;
      case Axis.vertical:
        return resolvedPadding!.horizontal;
    }
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    assert(resolvedPadding != null);
    final double beforePadding = this.beforePadding;
    final double afterPadding = this.afterPadding;
    final double mainAxisPadding = this.mainAxisPadding;
    final double crossAxisPadding = this.crossAxisPadding;
    if (child == null) {
      geometry = SliverGeometry(
        scrollExtent: mainAxisPadding,
        paintExtent: math.min(mainAxisPadding, constraints.remainingPaintExtent),
        maxPaintExtent: mainAxisPadding,
      );
      return;
    }
    final double beforePaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: beforePadding,
    );
    double overlap = constraints.overlap;
    if (overlap > 0) {
      overlap = math.max(0.0, constraints.overlap - beforePaddingPaintExtent);
    }
    child!.layout(
      constraints.copyWith(
        scrollOffset: math.max(0.0, constraints.scrollOffset - beforePadding),
        cacheOrigin: math.min(0.0, constraints.cacheOrigin + beforePadding),
        overlap: overlap,
        remainingPaintExtent: constraints.remainingPaintExtent - calculatePaintOffset(constraints, from: 0.0, to: beforePadding),
        remainingCacheExtent: constraints.remainingCacheExtent - calculateCacheOffset(constraints, from: 0.0, to: beforePadding),
        crossAxisExtent: math.max(0.0, constraints.crossAxisExtent - crossAxisPadding),
        precedingScrollExtent: beforePadding + constraints.precedingScrollExtent,
      ),
      parentUsesSize: true,
    );
    final SliverGeometry childLayoutGeometry = child!.geometry!;
    if (childLayoutGeometry.scrollOffsetCorrection != null) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
      );
      return;
    }
    final double afterPaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: beforePadding + childLayoutGeometry.scrollExtent,
      to: mainAxisPadding + childLayoutGeometry.scrollExtent,
    );
    final double mainAxisPaddingPaintExtent = beforePaddingPaintExtent + afterPaddingPaintExtent;
    final double beforePaddingCacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: beforePadding,
    );
    final double afterPaddingCacheExtent = calculateCacheOffset(
      constraints,
      from: beforePadding + childLayoutGeometry.scrollExtent,
      to: mainAxisPadding + childLayoutGeometry.scrollExtent,
    );
    final double mainAxisPaddingCacheExtent = afterPaddingCacheExtent + beforePaddingCacheExtent;
    final double paintExtent = math.min(
      beforePaddingPaintExtent + math.max(childLayoutGeometry.paintExtent, childLayoutGeometry.layoutExtent + afterPaddingPaintExtent),
      constraints.remainingPaintExtent,
    );
    geometry = SliverGeometry(
      paintOrigin: childLayoutGeometry.paintOrigin,
      scrollExtent: mainAxisPadding + childLayoutGeometry.scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: math.min(mainAxisPaddingPaintExtent + childLayoutGeometry.layoutExtent, paintExtent),
      cacheExtent: math.min(mainAxisPaddingCacheExtent + childLayoutGeometry.cacheExtent, constraints.remainingCacheExtent),
      maxPaintExtent: mainAxisPadding + childLayoutGeometry.maxPaintExtent,
      hitTestExtent: math.max(
        mainAxisPaddingPaintExtent + childLayoutGeometry.paintExtent,
        beforePaddingPaintExtent + childLayoutGeometry.hitTestExtent,
      ),
      hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
    );

    final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        childParentData.paintOffset = Offset(resolvedPadding!.left, calculatePaintOffset(constraints, from: resolvedPadding!.bottom + childLayoutGeometry.scrollExtent, to: resolvedPadding!.bottom + childLayoutGeometry.scrollExtent + resolvedPadding!.top));
        break;
      case AxisDirection.right:
        childParentData.paintOffset = Offset(calculatePaintOffset(constraints, from: 0.0, to: resolvedPadding!.left), resolvedPadding!.top);
        break;
      case AxisDirection.down:
        childParentData.paintOffset = Offset(resolvedPadding!.left, calculatePaintOffset(constraints, from: 0.0, to: resolvedPadding!.top));
        break;
      case AxisDirection.left:
        childParentData.paintOffset = Offset(calculatePaintOffset(constraints, from: resolvedPadding!.right + childLayoutGeometry.scrollExtent, to: resolvedPadding!.right + childLayoutGeometry.scrollExtent + resolvedPadding!.left), resolvedPadding!.top);
        break;
    }
    assert(childParentData.paintOffset != null);
    assert(beforePadding == this.beforePadding);
    assert(afterPadding == this.afterPadding);
    assert(mainAxisPadding == this.mainAxisPadding);
    assert(crossAxisPadding == this.crossAxisPadding);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, { required double mainAxisPosition, required double crossAxisPosition }) {
    if (child != null && child!.geometry!.hitTestExtent > 0.0) {
      final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
      result.addWithAxisOffset(
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
        mainAxisOffset: childMainAxisPosition(child!),
        crossAxisOffset: childCrossAxisPosition(child!),
        paintOffset: childParentData.paintOffset,
        hitTest: child!.hitTest,
      );
    }
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
    assert(resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
      case AxisDirection.down:
        return resolvedPadding!.left;
      case AxisDirection.left:
      case AxisDirection.right:
        return resolvedPadding!.top;
    }
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    return beforePadding;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry!.visible) {
      final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
      context.paintChild(child!, offset + childParentData.paintOffset);
    }
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    super.debugPaint(context, offset);
    assert(() {
      if (debugPaintSizeEnabled) {
        final Size parentSize = getAbsoluteSize();
        final Rect outerRect = offset & parentSize;
        Rect? innerRect;
        if (child != null) {
          final Size childSize = child!.getAbsoluteSize();
          final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
          innerRect = (offset + childParentData.paintOffset) & childSize;
          assert(innerRect.top >= outerRect.top);
          assert(innerRect.left >= outerRect.left);
          assert(innerRect.right <= outerRect.right);
          assert(innerRect.bottom <= outerRect.bottom);
        }
        debugPaintPadding(context.canvas, outerRect, innerRect);
      }
      return true;
    }());
  }
}

/// Insets a [RenderSliver], applying padding on each side.
///
/// A [RenderSliverPadding] object wraps the [SliverGeometry.layoutExtent] of
/// its child. Any incoming [SliverConstraints.overlap] is ignored and not
/// passed on to the child.
///
/// {@macro flutter.rendering.RenderSliverEdgeInsetsPadding}
class RenderSliverPadding extends RenderSliverEdgeInsetsPadding {
  /// Creates a render object that insets its child in a viewport.
  ///
  /// The [padding] argument must not be null and must have non-negative insets.
  RenderSliverPadding({
    required EdgeInsetsGeometry padding,
    TextDirection? textDirection,
    RenderSliver? child,
  }) : assert(padding != null),
       assert(padding.isNonNegative),
       _padding = padding,
       _textDirection = textDirection {
    this.child = child;
  }

  @override
  EdgeInsets? get resolvedPadding => _resolvedPadding;
  EdgeInsets? _resolvedPadding;

  void _resolve() {
    if (resolvedPadding != null)
      return;
    _resolvedPadding = padding.resolve(textDirection);
    assert(resolvedPadding!.isNonNegative);
  }

  void _markNeedsResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  /// The amount to pad the child in each dimension.
  ///
  /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
  /// must not be null.
  EdgeInsetsGeometry get padding => _padding;
  EdgeInsetsGeometry _padding;
  set padding(EdgeInsetsGeometry value) {
    assert(value != null);
    assert(padding.isNonNegative);
    if (_padding == value)
      return;
    _padding = value;
    _markNeedsResolution();
  }

  /// The text direction with which to resolve [padding].
  ///
  /// This may be changed to null, but only after the [padding] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value)
      return;
    _textDirection = value;
    _markNeedsResolution();
  }

  @override
  void performLayout() {
    _resolve();
    super.performLayout();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}
