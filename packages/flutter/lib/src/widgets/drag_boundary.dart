// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'framework.dart';

/// The interface for defining the algorithm that a boundary handles the specified type of shape to be dragged within.
///
/// See also:
///  * [DragBoundary], which uses this class.
///
/// [T] is the drag object position.
abstract class DragBoundaryDelegate<T> {
  /// Returns whether the specified drag object position is within the boundary.
  bool isWithinBoundary(T position);

  /// Returns the position of the given drag object after moving it fully inside
  /// the boundary with the shortest distance.
  T nearestPositionWithinBoundary(T position);
}

class _DragBoundaryDelegateForRect extends DragBoundaryDelegate<Rect> {
  _DragBoundaryDelegateForRect(this.boundary);
  final Rect boundary;
  @override
  bool isWithinBoundary(Rect position) {
    return boundary.contains(position.topLeft) && boundary.contains(position.bottomRight);
  }

  @override
  Rect nearestPositionWithinBoundary(Rect position) {
    assert(() {
      if (boundary.right - position.width < boundary.left ||
          boundary.bottom - position.height < boundary.top) {
        throw FlutterError(
          'The shape is larger than the boundary. '
          'The shape width must be less than the boundary width, and the shape height must be less than the boundary height.',
        );
      }
      return true;
    }());
    final double left = clampDouble(
      position.left,
      boundary.left,
      boundary.right - position.width,
    );
    final double top = clampDouble(
      position.top,
      boundary.top,
      boundary.bottom - position.height,
    );
    return Rect.fromLTWH(left, top, position.width, position.height);
  }
}

/// Provides a [DragBoundaryDelegate] for its descendants whose bounds are those defined by this widget.
///
/// {@tool dartpad}
/// This example demonstrates dragging a red box, constrained within the bounds
/// of a green box.
///
/// ** See code in examples/api/lib/widgets/gesture_detector/gesture_detector.3.dart **
/// {@end-tool}
class DragBoundary extends InheritedWidget {
  /// Creates a widget that provides a boundary to its descendants.
  const DragBoundary({required super.child, super.key});

  /// Retrieve the [DragBoundary] from the nearest ancestor to
  /// get its [DragBoundaryDelegate] of [Rect].
  ///
  /// [useGlobalPosition] Specifies whether to use global position.
  /// If false, the local position of the bounds are used.
  static DragBoundaryDelegate<Rect>? forRectOf(BuildContext context, {bool useGlobalPosition = false}) {
    final InheritedElement? element =
        context.getElementForInheritedWidgetOfExactType<DragBoundary>();
    if (element == null) {
      return null;
    }
    final RenderBox? rb = element.findRenderObject() as RenderBox?;
    assert(rb != null && rb.hasSize, 'DragBoundary is not available');
    final Rect boundary = (useGlobalPosition ? rb!.localToGlobal(Offset.zero) : Offset.zero) & rb!.size;
    return _DragBoundaryDelegateForRect(boundary);
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
