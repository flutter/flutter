// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of ui;

/// A complex, one-dimensional subset of a plane.
///
/// A path consists of a number of subpaths, and a _current point_.
///
/// Subpaths consist of segments of various types, such as lines,
/// arcs, or beziers. Subpaths can be open or closed, and can
/// self-intersect.
///
/// Closed subpaths enclose a (possibly discontiguous) region of the
/// plane based on the current [fillType].
///
/// The _current point_ is initially at the origin. After each
/// operation adding a segment to a subpath, the current point is
/// updated to the end of that segment.
///
/// Paths can be drawn on canvases using [Canvas.drawPath], and can
/// used to create clip regions using [Canvas.clipPath].
abstract class Path {
  /// Create a new empty [Path] object.
  factory Path() {
    if (engine.experimentalUseSkia) {
      return engine.SkPath();
    } else {
      return engine.SurfacePath();
    }
  }

  /// Creates a copy of another [Path].
  ///
  /// This copy is fast and does not require additional memory unless either
  /// the `source` path or the path returned by this constructor are modified.
  factory Path.from(Path source) {
    if (engine.experimentalUseSkia) {
      return engine.SkPath.from(source);
    } else {
      return engine.SurfacePath.from(source);
    }
  }

  /// Determines how the interior of this path is calculated.
  ///
  /// Defaults to the non-zero winding rule, [PathFillType.nonZero].
  PathFillType get fillType;
  set fillType(PathFillType value);

  /// Starts a new subpath at the given coordinate.
  void moveTo(double x, double y);

  /// Starts a new subpath at the given offset from the current point.
  void relativeMoveTo(double dx, double dy);

  /// Adds a straight line segment from the current point to the given
  /// point.
  void lineTo(double x, double y);

  /// Adds a straight line segment from the current point to the point
  /// at the given offset from the current point.
  void relativeLineTo(double dx, double dy);

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the given point (x2,y2), using the control point
  /// (x1,y1).
  void quadraticBezierTo(double x1, double y1, double x2, double y2);

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the point at the offset (x2,y2) from the current point,
  /// using the control point at the offset (x1,y1) from the current
  /// point.
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2);

  /// Adds a cubic bezier segment that curves from the current point
  /// to the given point (x3,y3), using the control points (x1,y1) and
  /// (x2,y2).
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3);

  /// Adds a cubic bezier segment that curves from the current point
  /// to the point at the offset (x3,y3) from the current point, using
  /// the control points at the offsets (x1,y1) and (x2,y2) from the
  /// current point.
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3);

  /// Adds a bezier segment that curves from the current point to the
  /// given point (x2,y2), using the control points (x1,y1) and the
  /// weight w. If the weight is greater than 1, then the curve is a
  /// hyperbola; if the weight equals 1, it's a parabola; and if it is
  /// less than 1, it is an ellipse.
  void conicTo(double x1, double y1, double x2, double y2, double w);

  /// Adds a bezier segment that curves from the current point to the
  /// point at the offset (x2,y2) from the current point, using the
  /// control point at the offset (x1,y1) from the current point and
  /// the weight w. If the weight is greater than 1, then the curve is
  /// a hyperbola; if the weight equals 1, it's a parabola; and if it
  /// is less than 1, it is an ellipse.
  void relativeConicTo(double x1, double y1, double x2, double y2, double w);

  /// If the `forceMoveTo` argument is false, adds a straight line
  /// segment and an arc segment.
  ///
  /// If the `forceMoveTo` argument is true, starts a new subpath
  /// consisting of an arc segment.
  ///
  /// In either case, the arc segment consists of the arc that follows
  /// the edge of the oval bounded by the given rectangle, from
  /// startAngle radians around the oval up to startAngle + sweepAngle
  /// radians around the oval, with zero radians being the point on
  /// the right hand side of the oval that crosses the horizontal line
  /// that intersects the center of the rectangle and with positive
  /// angles going clockwise around the oval.
  ///
  /// The line segment added if `forceMoveTo` is false starts at the
  /// current point and ends at the start of the arc.
  void arcTo(
      Rect rect, double startAngle, double sweepAngle, bool forceMoveTo);

  /// Appends up to four conic curves weighted to describe an oval of `radius`
  /// and rotated by `rotation`.
  ///
  /// The first curve begins from the last point in the path and the last ends
  /// at `arcEnd`. The curves follow a path in a direction determined by
  /// `clockwise` and `largeArc` in such a way that the sweep angle
  /// is always less than 360 degrees.
  ///
  /// A simple line is appended if either either radii are zero or the last
  /// point in the path is `arcEnd`. The radii are scaled to fit the last path
  /// point if both are greater than zero but too small to describe an arc.
  ///
  /// See Conversion from endpoint to center parametrization described in
  /// https://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter
  /// as reference for implementation.
  void arcToPoint(
      Offset arcEnd, {
        Radius radius = Radius.zero,
        double rotation = 0.0,
        bool largeArc = false,
        bool clockwise = true,
      });

  /// Appends up to four conic curves weighted to describe an oval of `radius`
  /// and rotated by `rotation`.
  ///
  /// The last path point is described by (px, py).
  ///
  /// The first curve begins from the last point in the path and the last ends
  /// at `arcEndDelta.dx + px` and `arcEndDelta.dy + py`. The curves follow a
  /// path in a direction determined by `clockwise` and `largeArc`
  /// in such a way that the sweep angle is always less than 360 degrees.
  ///
  /// A simple line is appended if either either radii are zero, or, both
  /// `arcEndDelta.dx` and `arcEndDelta.dy` are zero. The radii are scaled to
  /// fit the last path point if both are greater than zero but too small to
  /// describe an arc.
  void relativeArcToPoint(
      Offset arcEndDelta, {
        Radius radius = Radius.zero,
        double rotation = 0.0,
        bool largeArc = false,
        bool clockwise = true,
      });

  /// Adds a new subpath that consists of four lines that outline the
  /// given rectangle.
  void addRect(Rect rect);

  /// Adds a new subpath that consists of a curve that forms the
  /// ellipse that fills the given rectangle.
  ///
  /// To add a circle, pass an appropriate rectangle as `oval`.
  /// [Rect.fromCircle] can be used to easily describe the circle's center
  /// [Offset] and radius.
  void addOval(Rect oval);

  /// Adds a new subpath with one arc segment that consists of the arc
  /// that follows the edge of the oval bounded by the given
  /// rectangle, from startAngle radians around the oval up to
  /// startAngle + sweepAngle radians around the oval, with zero
  /// radians being the point on the right hand side of the oval that
  /// crosses the horizontal line that intersects the center of the
  /// rectangle and with positive angles going clockwise around the
  /// oval.
  void addArc(Rect oval, double startAngle, double sweepAngle);

  /// Adds a new subpath with a sequence of line segments that connect the given
  /// points.
  ///
  /// If `close` is true, a final line segment will be added that connects the
  /// last point to the first point.
  ///
  /// The `points` argument is interpreted as offsets from the origin.
  void addPolygon(List<Offset> points, bool close);

  /// Adds a new subpath that consists of the straight lines and
  /// curves needed to form the rounded rectangle described by the
  /// argument.
  void addRRect(RRect rrect);

  /// Adds a new subpath that consists of the given `path` offset by the given
  /// `offset`.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given offset. The matrix is a 4x4
  /// matrix stored in column major order.
  void addPath(Path path, Offset offset, {Float64List matrix4});

  /// Adds the given path to this path by extending the current segment of this
  /// path with the first segment of the given path.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given `offset`.  The matrix is a 4x4
  /// matrix stored in column major order.
  void extendWithPath(Path path, Offset offset, {Float64List matrix4});

  /// Closes the last subpath, as if a straight line had been drawn
  /// from the current point to the first point of the subpath.
  void close();

  /// Clears the [Path] object of all subpaths, returning it to the
  /// same state it had when it was created. The _current point_ is
  /// reset to the origin.
  void reset();

  /// Tests to see if the given point is within the path. (That is, whether the
  /// point would be in the visible portion of the path if the path was used
  /// with [Canvas.clipPath].)
  ///
  /// The `point` argument is interpreted as an offset from the origin.
  ///
  /// Returns true if the point is in the path, and false otherwise.
  ///
  /// Note: Not very efficient, it creates a canvas, plays path and calls
  /// Context2D isPointInPath. If performance becomes issue, retaining
  /// RawRecordingCanvas can remove create/remove rootElement cost.
  bool contains(Offset point);

  /// Returns a copy of the path with all the segments of every
  /// subpath translated by the given offset.
  Path shift(Offset offset);

  /// Returns a copy of the path with all the segments of every
  /// sub path transformed by the given matrix.
  Path transform(Float64List matrix4);

  /// Computes the bounding rectangle for this path.
  ///
  /// A path containing only axis-aligned points on the same straight line will
  /// have no area, and therefore `Rect.isEmpty` will return true for such a
  /// path. Consider checking `rect.width + rect.height > 0.0` instead, or
  /// using the [computeMetrics] API to check the path length.
  ///
  /// For many more elaborate paths, the bounds may be inaccurate.  For example,
  /// when a path contains a circle, the points used to compute the bounds are
  /// the circle's implied control points, which form a square around the
  /// circle; if the circle has a transformation applied using [transform] then
  /// that square is rotated, and the (axis-aligned, non-rotated) bounding box
  /// therefore ends up grossly overestimating the actual area covered by the
  /// circle.
  // see https://skia.org/user/api/SkPath_Reference#SkPath_getBounds
  Rect getBounds();

  /// Combines the two paths according to the manner specified by the given
  /// `operation`.
  ///
  /// The resulting path will be constructed from non-overlapping contours. The
  /// curve order is reduced where possible so that cubics may be turned into
  /// quadratics, and quadratics maybe turned into lines.
  static Path combine(PathOperation operation, Path path1, Path path2) {
    assert(path1 != null);
    assert(path2 != null);
    if (engine.experimentalUseSkia) {
      return engine.SkPath.combine(operation, path1, path2);
    }
    throw UnimplementedError();
  }

  /// Creates a [PathMetrics] object for this path.
  ///
  /// If `forceClosed` is set to true, the contours of the path will be measured
  /// as if they had been closed, even if they were not explicitly closed.
  PathMetrics computeMetrics({bool forceClosed = false});
}
