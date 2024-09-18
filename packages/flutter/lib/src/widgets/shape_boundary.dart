// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'framework.dart';

/// An abstract class that defines the boundaries of a geometric shape.
///
/// [isWithinBoundary] return whether the specified shape is within the boundary.
///
/// [nearestShapeWithinBoundary] returns a shape within the boundary closest to
/// the given shape, or returns the given shape if it is within the boundary.
///
/// See also:
/// * [OffsetBoundaryProvider], A widget that provides a [ShapeBoundary] for an [Offset].
/// * [RectBoundaryProvider], A widget that provides a [ShapeBoundary] for a [Rect].
abstract class ShapeBoundary<T> {
  /// Returns whether the specified shape is within the boundary.
  bool isWithinBoundary(T shape);

  /// Returns the shape closest to the specified shape within the boundary.
  /// If the specified shape is within the boundary, it returns the shape as is.
  T nearestShapeWithinBoundary(T shape);
}

/// This widget can provide a [ShapeBoundary] of [Offset] to its descendants,
/// whose bounds is the current position of this widget.
///
/// [ShapeBoundary.isWithinBoundary] returns whether the specified [Offset]
/// is within the range of this widget. [Offset] should be specified in global coordinates.
///
/// [ShapeBoundary.nearestShapeWithinBoundary] returns the [Offset] closest to the specified [Offset]
/// within the boundary, or returns the [Offset] as is if it is within the boundary.
class OffsetBoundaryProvider extends InheritedWidget {
  /// Creates a widget that provides a [ShapeBoundary] of [Offset] to its descendants.
  const OffsetBoundaryProvider({required super.child, super.key});

  @override
  InheritedElement createElement() => _OffsetBoundaryInheritedElement(this);

  /// Retrieve the [OffsetBoundaryProvider] from the nearest ancestor to
  /// get its [ShapeBoundary] of [Offset].
  static ShapeBoundary<Offset>? maybeOf(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<OffsetBoundaryProvider>();
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
  bool isWithinBoundary(Offset shape) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    return boundary.contains(shape);
  }

  @override
  Offset nearestShapeWithinBoundary(Offset shape) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    final double dx = clampDouble(shape.dx, boundary.left, boundary.right);
    final double top = clampDouble(shape.dy, boundary.top, boundary.bottom);
    return Offset(dx, top);
  }
}

/// This widget can provide a [ShapeBoundary] of [Rect] to its descendants,
/// whose bounds is the current position of this widget.
///
/// [ShapeBoundary.isWithinBoundary] returns whether the specified [Rect]
/// is within the range of this widget. [Rect] should be specified in global coordinates
///
/// [ShapeBoundary.nearestShapeWithinBoundary] returns the [Rect] with the boundary
/// that is closest to the specified [Rect], or returns the [Rect] if it is within the boundary.
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
  bool isWithinBoundary(Rect shape) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    return boundary.contains(shape.topLeft) &&
        boundary.contains(shape.topRight) &&
        boundary.contains(shape.bottomLeft) &&
        boundary.contains(shape.bottomRight);
  }

  @override
  Rect nearestShapeWithinBoundary(Rect shape) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Rect boundary = rb!.localToGlobal(Offset.zero) & rb.size;
    final double left = clampDouble(shape.left, boundary.left, boundary.right - shape.width);
    final double top = clampDouble(shape.top, boundary.top, boundary.bottom - shape.height);
    return Rect.fromLTWH(left, top, shape.width, shape.height);
  }
}
