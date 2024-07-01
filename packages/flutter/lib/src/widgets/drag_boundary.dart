// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';

/// Provides a boundary for a drag gesture.
///
/// This class is used to define the boundary for a drag gesture.
/// It can be extended to provide custom boundaries.
///
/// {@tool dartpad}
/// This example demonstrates dragging a red box, constrained within the bounds
/// of a green box.
///
/// ** See code in examples/api/lib/widgets/gesture_detector/gesture_detector.3.dart **
/// {@end-tool}
///
/// See also:
/// * [DragPointBoundary], which provides a boundary for a drag point.
/// * [DragRectBoundaryProvider], which provides a boundary for a drag rectangle.
abstract class GestureDragBoundaryProvider {
  /// Returns the boundary for the drag gesture.
  ///
  /// The [context] parameter usually represents the widget of the drag object.
  /// For [DragRectBoundaryProvider], it is used as the dragged rectangle.
  ///
  /// The [initialPosition] parameter represents the initial position of the drag gesture.
  DragBoundary getDragBoundary(BuildContext context, Offset initialPosition);
}

class _GestureRectBoundaryProvider extends GestureDragBoundaryProvider {
  _GestureRectBoundaryProvider(this.boundary);
  final Rect boundary;
  @override
  DragBoundary getDragBoundary(BuildContext context, Offset initialPosition) {
    final Size size = context.size!;
    final Offset offset = (context.findRenderObject()! as RenderBox).globalToLocal(initialPosition);
    return DragRectBoundary(boundary: boundary, rectSize: size, rectOffset: offset);
  }
}

/// This widget creates a [GestureDragBoundaryProvider] that sets the boundary for a
/// dragged rectangle. The drag rectangle is retrieved from the context provided in
/// [GestureDragBoundaryProvider.getDragBoundary]. The boundary is defined by
/// the rectangle bounds of the provided child widget.
///
/// See also:
/// * [DragPointBoundaryProvider], a widget that provides bounds for the drag point
/// to descendants.
/// * [DragRectBoundary], a class that defines drag bounds for a rectangle.
/// * [DragPointBoundary], a class that defines drag bounds for a point.
class DragRectBoundaryProvider extends InheritedWidget {
  /// Creates a widget that provides a [GestureDragBoundaryProvider] to its descendants.
  const DragRectBoundaryProvider({required super.child, super.key});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  /// Retrieves the [GestureDragBoundaryProvider] from the nearest ancestor
  /// [DragRectBoundaryProvider] widget.
  static GestureDragBoundaryProvider? of(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<DragRectBoundaryProvider>();
    if (element == null) {
      return null;
    }
    final RenderBox? rb = element.findRenderObject() as RenderBox?;
    assert(rb != null && rb.hasSize, 'RenderBox is not ready yet, You may be accessing before the drag gesture starts');
    return _GestureRectBoundaryProvider(rb!.localToGlobal(Offset.zero) & rb.size);
  }
}

class _GesturePointBoundaryProvider extends GestureDragBoundaryProvider {
  _GesturePointBoundaryProvider(this.boundary);
  final Rect boundary;
  @override
  DragBoundary getDragBoundary(BuildContext context, Offset initialPosition) {
    return DragPointBoundary(boundary);
  }
}

/// This widget creates a [GestureDragBoundaryProvider] that sets a boundary for a
/// dragged point. The dragged point is retrieved from the [Offset] provided in
/// [GestureDragBoundaryProvider.getDragBoundary]. The boundary is defined by the
/// rectangle bounds of the provided child widget.
///
/// See also:
/// * [DragRectBoundaryProvider], A widget that provides bounds for the drag rectangle
/// to descendants
/// * [DragRectBoundary], a class that defines drag bounds for a rectangle.
/// * [DragPointBoundary], a class that defines drag bounds for a point.
class DragPointBoundaryProvider extends InheritedWidget {
  /// Creates a widget that provides a [GestureDragBoundaryProvider] to its descendants.
  const DragPointBoundaryProvider({required super.child, super.key});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  /// Retrieves the [GestureDragBoundaryProvider] from the nearest ancestor
  /// [DragPointBoundaryProvider] widget.
  static GestureDragBoundaryProvider? of(BuildContext context) {
    final InheritedElement? element = context.getElementForInheritedWidgetOfExactType<DragPointBoundaryProvider>();
    if (element == null) {
      return null;
    }
    final RenderBox? rb = element.findRenderObject() as RenderBox?;
    assert(rb != null && rb.hasSize, 'RenderBox is not ready yet, You may be accessing before the drag gesture starts');
    return _GesturePointBoundaryProvider(rb!.localToGlobal(Offset.zero) & rb.size);
  }
}
