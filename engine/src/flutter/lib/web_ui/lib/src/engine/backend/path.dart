// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

/// Represents a vector path that can be rendered or manipulated.
abstract class BackendPath {
  /// Disposes of the resources held by this path.
  void dispose();

  /// Computes the bounding box of this path.
  ui.Rect getBounds();

  /// Computes the metrics (such as length and tangents) for each contour in the path.
  BackendPathMetricIterator computeMetrics({bool forceClosed = false});

  // In order to properly clip platform views with paths, we need to be able to get a
  // string representation of them.
  /// Returns an SVG path string representation of the path, e.g. for clipping platform views.
  String toSvgString();
}

/// A builder interface for constructing a [BackendPath] sequentially.
abstract class BackendPathBuilder {
  /// The fill type of the path, determining how the interior of the path is calculated.
  ui.PathFillType get fillType;
  set fillType(ui.PathFillType value);

  /// Starts a new sub-path at the given coordinates.
  void moveTo(double x, double y);

  /// Starts a new sub-path at the given offset relative to the current point.
  void relativeMoveTo(double dx, double dy);

  /// Adds a straight line segment from the current point to the given coordinates.
  void lineTo(double x, double y);

  /// Adds a straight line segment from the current point to the given offset relative to the current point.
  void relativeLineTo(double dx, double dy);

  /// Adds a quadratic bezier segment from the current point to `(x2, y2)` using `(x1, y1)` as control point.
  void quadraticBezierTo(double x1, double y1, double x2, double y2);

  /// Adds a quadratic bezier segment relative to the current point.
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2);

  /// Adds a cubic bezier segment from the current point to `(x3, y3)` using control points `(x1, y1)` and `(x2, y2)`.
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3);

  /// Adds a cubic bezier segment relative to the current point.
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3);

  /// Adds a conic segment from the current point to `(x2, y2)` with control point `(x1, y1)` and weight `w`.
  void conicTo(double x1, double y1, double x2, double y2, double w);

  /// Adds a conic segment relative to the current point.
  void relativeConicTo(double x1, double y1, double x2, double y2, double w);

  /// Adds an arc segment to the given rectangle.
  void arcTo(ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo);

  /// Adds an arc segment from the current point to the given end point.
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  });

  /// Adds a relative arc segment from the current point to the given offset.
  void relativeArcToPoint(
    ui.Offset arcEndDelta, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  });

  /// Adds a closed rectangular sub-path.
  void addRect(ui.Rect rect);

  /// Adds a closed oval sub-path that fits inside the given rectangle.
  void addOval(ui.Rect oval);

  /// Adds an arc of an oval as a sub-path.
  void addArc(ui.Rect oval, double startAngle, double sweepAngle);

  /// Adds a polygon sub-path with the given points.
  void addPolygon(List<ui.Offset> points, bool close);

  /// Adds a rounded rectangular sub-path.
  void addRRect(ui.RRect rrect);

  /// Adds a rounded superelliptical sub-path.
  void addRSuperellipse(ui.RSuperellipse rsuperellipse);

  /// Shifts the path coordinates in place by the given offset.
  void shiftInPlace(ui.Offset offset);

  /// Transforms the path coordinates in place using the given 4x4 matrix.
  void transformInPlace(Float64List matrix4);

  /// Adds the contours of another path to this path, with an offset and optional transform.
  void addPath(BackendPath path, ui.Offset offset, {Float64List? matrix4});

  /// Appends another path to this path, with an offset and optional transform.
  void extendWithPath(BackendPath path, ui.Offset offset, {Float64List? matrix4});

  /// Closes the current sub-path, drawing a line back to its starting point.
  void close();

  /// Resets the builder, clearing all sub-paths and resetting the fill type.
  void reset();

  /// Returns whether the given point lies inside the path.
  bool contains(ui.Offset point);

  /// Computes the bounding box of the constructed path so far.
  ui.Rect getBounds();

  /// Builds and returns the constructed [BackendPath].
  BackendPath build();

  /// Disposes of the builder and its internal resources.
  void dispose();
}

/// An iterator over the metrics of each contour in a path.
abstract class BackendPathMetricIterator implements Iterator<BackendPathMetric> {
  @override
  /// The current [BackendPathMetric] in the iteration.
  BackendPathMetric get current;

  /// Disposes of the iterator.
  void dispose();
}

/// Represents the metrics of a single contour within a path.
abstract class BackendPathMetric {
  /// Extracts a sub-path of this contour from `start` to `end` distance.
  BackendPathBuilder extractPath(double start, double end, {bool startWithMoveTo = true});

  /// Calculates the tangent (position and direction) at the given distance along the contour.
  ui.Tangent? getTangentForOffset(double distance);

  /// Whether the contour is closed.
  bool get isClosed;

  /// The total length of the contour.
  double get length;

  /// Disposes of the metric object.
  void dispose();
}

/// Factory interface for creating [BackendPathBuilder] instances.
abstract class BackendPathConstructors {
  /// Creates a new, empty [BackendPathBuilder].
  BackendPathBuilder createNew();

  /// Creates a new [BackendPathBuilder] initialized with the contents of the given [BackendPath].
  BackendPathBuilder fromPath(BackendPath path);

  /// Creates a new [BackendPathBuilder] by combining two paths using a path operation.
  BackendPathBuilder combinePaths(ui.PathOperation operation, BackendPath path1, BackendPath path2);
}
