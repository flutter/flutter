// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'framework.dart';

/// Convert the shape position from global to local.
typedef ShapePositionGlobalToLocal = Offset Function(Offset point);

/// An abstract class that defines a boundary for regulating a specific type of shape.
///
/// `T` represents the shape type. For example, `T` can be an `Offset` if the boundary
/// regulates a point, or a `Rect` if it regulates a rectangle.
///
/// See also:
/// * [PointBoundaryRegulatorProvider], A widget that provides a [ShapeBoundaryRegulator] for a point.
/// * [RectBoundaryRegulatorProvider], A widget that provides a [ShapeBoundaryRegulator] for a [Rect].
abstract class ShapeBoundaryRegulator<T> {
  /// Returns whether the specified shape position is within the boundary.
  ///
  /// {@template flutter.widgets.ShapeBoundaryRegulator}
  /// [shapePosition] is the position of the shape to be checked.
  ///
  /// [globalToLocal] If the given shape position is not the global position, this
  /// method can convert the global position to the local position where the shape is located.
  /// {@endtemplate}
  bool isWithinBoundary(T shapePosition, {ShapePositionGlobalToLocal? globalToLocal});

  /// Returns the position of the given shape after moving it fully inside the boundary
  /// with the shortest distance.
  ///
  /// {@macro flutter.widgets.ShapeBoundaryRegulator}
  T nearestPositionWithinBoundary(T shapePosition, {ShapePositionGlobalToLocal? globalToLocal});
}

/// Provides a [ShapeBoundaryRegulator] to its descendants, regulating point positions
/// within the boundary defined by this widget.
class PointBoundaryRegulatorProvider extends InheritedWidget {
  /// Creates a widget that provides a [ShapeBoundaryRegulator] of [Offset] to its descendants.
  const PointBoundaryRegulatorProvider({required super.child, super.key});

  @override
  InheritedElement createElement() => _OffsetBoundaryRegulatorInheritedElement(this);

  /// Retrieve the [PointBoundaryRegulatorProvider] from the nearest ancestor to
  /// get its [ShapeBoundaryRegulator] of [Offset].
  static ShapeBoundaryRegulator<Offset>? maybeOf(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<PointBoundaryRegulatorProvider>();
    if (element == null) {
      return null;
    }
    return element as _OffsetBoundaryRegulatorInheritedElement;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class _OffsetBoundaryRegulatorInheritedElement extends InheritedElement implements ShapeBoundaryRegulator<Offset> {
  _OffsetBoundaryRegulatorInheritedElement(super.widget);

  @override
  bool isWithinBoundary(Offset shapePosition, {ShapePositionGlobalToLocal? globalToLocal}) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Offset topLeft = rb!.localToGlobal(Offset.zero);
    final Rect boundary = (globalToLocal?.call(topLeft) ?? topLeft) & rb.size;
    return boundary.contains(shapePosition);
  }

  @override
  Offset nearestPositionWithinBoundary(Offset shapePosition, {ShapePositionGlobalToLocal? globalToLocal}) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'OffsetBoundaryProvider is not available');
    final Offset topLeft = rb!.localToGlobal(Offset.zero);
    final Rect boundary = (globalToLocal?.call(topLeft) ?? topLeft) & rb.size;
    final double dx = clampDouble(shapePosition.dx, boundary.left, boundary.right);
    final double dy = clampDouble(shapePosition.dy, boundary.top, boundary.bottom);
    return Offset(dx, dy);
  }
}

/// Provides a [ShapeBoundaryRegulator] to its descendants, regulating rect positions
/// within the boundary defined by this widget.
///
/// {@tool dartpad}
/// This example demonstrates dragging a red box, constrained within the bounds
/// of a green box.
///
/// ** See code in examples/api/lib/widgets/gesture_detector/gesture_detector.3.dart **
/// {@end-tool}
class RectBoundaryRegulatorProvider extends InheritedWidget {
  /// Creates a widget that provides a [ShapeBoundaryRegulator] of [Rect] to its descendants.
  const RectBoundaryRegulatorProvider({required super.child, super.key});

  @override
  InheritedElement createElement() => _RectBoundaryRegulatorInheritedElement(this);

  /// Retrieve the [RectBoundaryRegulatorProvider] from the nearest ancestor to
  /// get its [ShapeBoundaryRegulator] of [Rect].
  static ShapeBoundaryRegulator<Rect>? maybeOf(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<RectBoundaryRegulatorProvider>();
    if (element == null) {
      return null;
    }
    return element as _RectBoundaryRegulatorInheritedElement;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class _RectBoundaryRegulatorInheritedElement extends InheritedElement implements ShapeBoundaryRegulator<Rect> {
  _RectBoundaryRegulatorInheritedElement(super.widget);

  @override
  bool isWithinBoundary(Rect shapePosition, {ShapePositionGlobalToLocal? globalToLocal}) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Offset topLeft = rb!.localToGlobal(Offset.zero);
    final Rect boundary = (globalToLocal?.call(topLeft) ?? topLeft) & rb.size;
    return boundary.contains(shapePosition.topLeft) &&
        boundary.contains(shapePosition.bottomRight);
  }

  @override
  Rect nearestPositionWithinBoundary(Rect shapePosition, {ShapePositionGlobalToLocal? globalToLocal}) {
    final RenderBox? rb = renderObject as RenderBox?;
    assert(rb != null && rb.hasSize, 'RectBoundaryProvider is not available');
    final Offset topLeft = rb!.localToGlobal(Offset.zero);
    final Rect boundary = (globalToLocal?.call(topLeft) ?? topLeft) & rb.size;
    assert(() {
      if (boundary.right - shapePosition.width < boundary.left ||
          boundary.bottom - shapePosition.height < boundary.top) {
        throw FlutterError(
          'The shape is larger than the boundary. '
          'The shape width must be less than the boundary width, and the shape height must be less than the boundary height.',
        );
      }
      return true;
    }());
    final double left = clampDouble(shapePosition.left, boundary.left, boundary.right - shapePosition.width);
    final double top = clampDouble(shapePosition.top, boundary.top, boundary.bottom - shapePosition.height);
    return Rect.fromLTWH(left, top, shapePosition.width, shapePosition.height);
  }
}
