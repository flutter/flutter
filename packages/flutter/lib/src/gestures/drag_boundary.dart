// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

/// An abstract class that defines a boundary for a drag gesture.
///
/// This class provides methods to determine if a drag gesture is within
/// the boundary ([isWithinBoundary]) and to find the nearest position
/// within the boundary when the drag gesture is outside
/// ([getNearestPositionWithinBoundary]).
///
/// See also:
/// * [DragPointBoundary], which defines a boundary for a drag point.
/// * [DragRectBoundary], which defines a boundary for a drag rectangle.
abstract class DragBoundary {
  /// Determines whether the given global location of a drag gesture
  /// is within the boundary.
  ///
  /// Returns `true` if the location is within the boundary, and `false`
  /// otherwise.
  bool isWithinBoundary(Offset globalLocation);

  /// Given a global location that is outside the boundary, finds and
  /// returns the nearest position within the boundary.
  ///
  /// Returns an [Offset] representing the nearest position within the
  /// boundary.
  Offset getNearestPositionWithinBoundary(Offset globalLocation);
}

/// Defines a boundary for a drag point.
///
/// This class extends [DragBoundary] and is used to determine whether
/// the currently dragged point is within the specified boundary.
///
/// The [isWithinBoundary] method checks if a given global location is
/// within the boundary.
///
/// The [getNearestPositionWithinBoundary] method takes a global location
/// that is outside the boundary and returns the nearest position within
/// the boundary.
class DragPointBoundary extends DragBoundary {
  /// Creates a [DragPointBoundary] with the given [boundary].
  DragPointBoundary(this.boundary);

  /// The boundary of the drag gesture.
  final Rect boundary;

  @override
  bool isWithinBoundary(Offset globalLocation) {
    return boundary.contains(globalLocation);
  }

  @override
  Offset getNearestPositionWithinBoundary(Offset globalLocation) {
    final double dx = clampDouble(globalLocation.dx, boundary.left, boundary.right);
    final double dy = clampDouble(globalLocation.dy, boundary.top, boundary.bottom);
    return Offset(dx, dy);
  }
}

/// Defines a boundary for a drag rectangle.
///
/// This class extends [DragBoundary] and is used to determine whether
/// the rectangle being dragged is within the specified boundary.
///
/// The rectangle is defined by its top left corner (the drag point)
/// and its size.
///
/// The [isWithinBoundary] method checks if the entire rectangle is
/// within the boundary.
///
/// The [getNearestPositionWithinBoundary] method takes a global location
/// that is outside the boundary and returns the nearest position within
/// the boundary that the rectangle can be dragged to.
class DragRectBoundary extends DragBoundary {
  /// Creates a [DragRectBoundary] with the given [boundary],
  /// [rectOffset], and [rectSize].
  ///
  /// [boundary] defines the boundary of the drag gesture. [rectOffset]
  /// is the offset of the top left corner of the dragged rectangle
  /// from the drag point. [rectSize] is the size of the dragged rectangle.
  DragRectBoundary({
    required this.boundary,
    required this.rectOffset,
    required this.rectSize,
  });

  /// Defines the boundary within which the drag gesture should
  /// be contained.
  final Rect boundary;

  /// Represents the offset of the top left corner of the dragged rectangle
  /// from the drag point. This is used to calculate the actual position
  /// of the rectangle.
  final Offset rectOffset;

  /// Specifies the size of the rectangle being dragged. This is used in
  /// conjunction with [rectOffset] to determine the actual boundaries
  /// of the rectangle.
  final Size rectSize;

  @override
  Offset getNearestPositionWithinBoundary(Offset globalLocation) {
    final Rect boundingRects = boundary.shift(rectOffset);
    final double adjustedX = clampDouble(
      globalLocation.dx,
      boundingRects.left,
      math.max(boundingRects.left, boundingRects.right - rectSize.width),
    );
    final double adjustedY = clampDouble(
      globalLocation.dy,
      boundingRects.top,
      math.max(boundingRects.top, boundingRects.bottom - rectSize.height),
    );
    return Offset(adjustedX, adjustedY);
  }

  @override
  bool isWithinBoundary(Offset globalLocation) {
    final Rect boundingRects = (globalLocation - rectOffset) & rectSize;
    return boundary.contains(boundingRects.topLeft) &&
        boundary.contains(boundingRects.topRight) &&
        boundary.contains(boundingRects.bottomLeft) &&
        boundary.contains(boundingRects.bottomRight);
  }
}
