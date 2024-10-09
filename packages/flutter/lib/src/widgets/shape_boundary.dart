// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'framework.dart';

/// An abstract class that defines a boundary for regulating a specific type of shape.
///
/// `T` represents the shape type. For example, `T` can be an `Offset` if the boundary
/// regulates a point, or a `Rect` if it regulates a rectangle.
///
/// See also:
/// * [PointBoundaryProvider], A widget that provides a [ShapeBoundary] for a point.
/// * [RectBoundaryProvider], A widget that provides a [ShapeBoundary] for a [Rect].
abstract class ShapeBoundary<T> {
  /// Returns whether the specified shape position is within the boundary.
  bool isWithinBoundary(T shapePosition);

  /// Returns the position of the given shape after moving it fully inside the boundary
  /// with the shortest distance.
  T nearestPositionWithinBoundary(T shapePosition);
}

/// Provides a [ShapeBoundary] to its descendants, regulating point positions
/// within the boundary defined by this widget.
class PointBoundaryProvider extends InheritedWidget {
  /// Creates a widget that provides a [ShapeBoundary] of [Offset] to its descendants.
  const PointBoundaryProvider({required super.child, super.key});

  @override
  InheritedElement createElement() => _OffsetBoundaryInheritedElement(this);

  /// Retrieve the [PointBoundaryProvider] from the nearest ancestor to
  /// get its [ShapeBoundary] of [Offset].
  static ShapeBoundary<Offset>? maybeOf(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<PointBoundaryProvider>();
    if (element == null) {
      return null;
    }
    return element as _OffsetBoundaryInheritedElement;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class _OffsetBoundaryInheritedElement extends InheritedElement implements ShapeBoundary<Offset> {
  _OffsetBoundaryInheritedElement(super.widget);

  @override
  bool isWithinBoundary(Offset shapePosition) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    return boundary.contains(shapePosition);
  }

  @override
  Offset nearestPositionWithinBoundary(Offset shapePosition) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    final double dx = clampDouble(shapePosition.dx, boundary.left, boundary.right);
    final double dy = clampDouble(shapePosition.dy, boundary.top, boundary.bottom);
    return Offset(dx, dy);
  }
}

/// Provides a [ShapeBoundary] to its descendants, regulating rect positions
/// within the boundary defined by this widget.
///
/// {@tool dartpad}
/// This example demonstrates dragging a red box, constrained within the bounds
/// of a green box.
///
/// ** See code in examples/api/lib/widgets/gesture_detector/gesture_detector.3.dart **
/// {@end-tool}
class RectBoundaryProvider extends InheritedWidget {
  /// Creates a widget that provides a [ShapeBoundary] of [Rect] to its descendants.
  const RectBoundaryProvider({required super.child, super.key});

  @override
  InheritedElement createElement() => _RectBoundaryInheritedElement(this);

  /// Retrieve the [RectBoundaryProvider] from the nearest ancestor to
  /// get its [ShapeBoundary] of [Rect].
  static ShapeBoundary<Rect>? maybeOf(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<RectBoundaryProvider>();
    if (element == null) {
      return null;
    }
    return element as _RectBoundaryInheritedElement;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class _RectBoundaryInheritedElement extends InheritedElement implements ShapeBoundary<Rect> {
  _RectBoundaryInheritedElement(super.widget);

  @override
  bool isWithinBoundary(Rect shapePosition) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    return boundary.contains(shapePosition.topLeft) &&
        boundary.contains(shapePosition.bottomRight);
  }

  @override
  Rect nearestPositionWithinBoundary(Rect shapePosition) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    final double left = clampDouble(shapePosition.left, boundary.left, boundary.right - shapePosition.width);
    final double top = clampDouble(shapePosition.top, boundary.top, boundary.bottom - shapePosition.height);
    return Rect.fromLTWH(left, top, shapePosition.width, shapePosition.height);
  }
}
