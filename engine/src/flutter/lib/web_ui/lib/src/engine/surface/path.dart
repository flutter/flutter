// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

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
class SurfacePath implements ui.Path {
  final List<Subpath> subpaths;
  ui.PathFillType _fillType = ui.PathFillType.nonZero;

  Subpath get _currentSubpath => subpaths.isEmpty ? null : subpaths.last;

  List<PathCommand> get _commands => _currentSubpath?.commands;

  /// The current x-coordinate for this path.
  double get _currentX => _currentSubpath?.currentX ?? 0.0;

  /// The current y-coordinate for this path.
  double get _currentY => _currentSubpath?.currentY ?? 0.0;

  /// Recorder used for hit testing paths.
  static ui.RawRecordingCanvas _rawRecorder;

  SurfacePath() : subpaths = <Subpath>[];

  /// Creates a copy of another [Path].
  ///
  /// This copy is fast and does not require additional memory unless either
  /// the `source` path or the path returned by this constructor are modified.
  SurfacePath.from(SurfacePath source) : subpaths = _deepCopy(source.subpaths);

  SurfacePath._shallowCopy(SurfacePath source)
      : subpaths = List<Subpath>.from(source.subpaths);

  SurfacePath._clone(this.subpaths, this._fillType);

  static List<Subpath> _deepCopy(List<Subpath> source) {
    // The last sub path can potentially still be mutated by calling ops.
    // Copy all sub paths except the last active one which needs a deep copy.
    final List<Subpath> paths = [];
    int len = source.length;
    if (len != 0) {
      --len;
      for (int i = 0; i < len; i++) {
        paths.add(source[i]);
      }
      paths.add(source[len].shift(const ui.Offset(0, 0)));
    }
    return paths;
  }

  /// Determines how the interior of this path is calculated.
  ///
  /// Defaults to the non-zero winding rule, [PathFillType.nonZero].
  @override
  ui.PathFillType get fillType => _fillType;
  @override
  set fillType(ui.PathFillType value) {
    _fillType = value;
  }

  /// Opens a new subpath with starting point (x, y).
  void _openNewSubpath(double x, double y) {
    subpaths.add(Subpath(x, y));
    _setCurrentPoint(x, y);
  }

  /// Sets the current point to (x, y).
  void _setCurrentPoint(double x, double y) {
    _currentSubpath.currentX = x;
    _currentSubpath.currentY = y;
  }

  /// Starts a new subpath at the given coordinate.
  @override
  void moveTo(double x, double y) {
    _openNewSubpath(x, y);
    _commands.add(MoveTo(x, y));
  }

  /// Starts a new subpath at the given offset from the current point.
  @override
  void relativeMoveTo(double dx, double dy) {
    final double newX = _currentX + dx;
    final double newY = _currentY + dy;
    _openNewSubpath(newX, newY);
    _commands.add(MoveTo(newX, newY));
  }

  /// Adds a straight line segment from the current point to the given
  /// point.
  @override
  void lineTo(double x, double y) {
    if (subpaths.isEmpty) {
      moveTo(0.0, 0.0);
    }
    _commands.add(LineTo(x, y));
    _setCurrentPoint(x, y);
  }

  /// Adds a straight line segment from the current point to the point
  /// at the given offset from the current point.
  @override
  void relativeLineTo(double dx, double dy) {
    final double newX = _currentX + dx;
    final double newY = _currentY + dy;
    if (subpaths.isEmpty) {
      moveTo(0.0, 0.0);
    }
    _commands.add(LineTo(newX, newY));
    _setCurrentPoint(newX, newY);
  }

  void _ensurePathStarted() {
    if (subpaths.isEmpty) {
      subpaths.add(Subpath(0.0, 0.0));
    }
  }

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the given point (x2,y2), using the control point
  /// (x1,y1).
  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _ensurePathStarted();
    _commands.add(QuadraticCurveTo(x1, y1, x2, y2));
    _setCurrentPoint(x2, y2);
  }

  /// Adds a quadratic bezier segment that curves from the current
  /// point to the point at the offset (x2,y2) from the current point,
  /// using the control point at the offset (x1,y1) from the current
  /// point.
  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _ensurePathStarted();
    _commands.add(QuadraticCurveTo(
        x1 + _currentX, y1 + _currentY, x2 + _currentX, y2 + _currentY));
    _setCurrentPoint(x2 + _currentX, y2 + _currentY);
  }

  /// Adds a cubic bezier segment that curves from the current point
  /// to the given point (x3,y3), using the control points (x1,y1) and
  /// (x2,y2).
  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _ensurePathStarted();
    _commands.add(BezierCurveTo(x1, y1, x2, y2, x3, y3));
    _setCurrentPoint(x3, y3);
  }

  /// Adds a cubic bezier segment that curves from the current point
  /// to the point at the offset (x3,y3) from the current point, using
  /// the control points at the offsets (x1,y1) and (x2,y2) from the
  /// current point.
  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _ensurePathStarted();
    _commands.add(BezierCurveTo(x1 + _currentX, y1 + _currentY, x2 + _currentX,
        y2 + _currentY, x3 + _currentX, y3 + _currentY));
    _setCurrentPoint(x3 + _currentX, y3 + _currentY);
  }

  /// Adds a bezier segment that curves from the current point to the
  /// given point (x2,y2), using the control points (x1,y1) and the
  /// weight w. If the weight is greater than 1, then the curve is a
  /// hyperbola; if the weight equals 1, it's a parabola; and if it is
  /// less than 1, it is an ellipse.
  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    final List<ui.Offset> quads =
        Conic(_currentX, _currentY, x1, y1, x2, y2, w).toQuads();
    final int len = quads.length;
    for (int i = 1; i < len; i += 2) {
      quadraticBezierTo(
          quads[i].dx, quads[i].dy, quads[i + 1].dx, quads[i + 1].dy);
    }
  }

  /// Adds a bezier segment that curves from the current point to the
  /// point at the offset (x2,y2) from the current point, using the
  /// control point at the offset (x1,y1) from the current point and
  /// the weight w. If the weight is greater than 1, then the curve is
  /// a hyperbola; if the weight equals 1, it's a parabola; and if it
  /// is less than 1, it is an ellipse.
  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    conicTo(_currentX + x1, _currentY + y1, _currentX + x2, _currentY + y2, w);
  }

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
  @override
  void arcTo(
      ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    assert(rectIsValid(rect));
    final ui.Offset center = rect.center;
    final double radiusX = rect.width / 2;
    final double radiusY = rect.height / 2;
    final double startX = radiusX * math.cos(startAngle) + center.dx;
    final double startY = radiusY * math.sin(startAngle) + center.dy;
    if (forceMoveTo) {
      _openNewSubpath(startX, startY);
    } else {
      lineTo(startX, startY);
    }
    _commands.add(Ellipse(center.dx, center.dy, radiusX, radiusY, 0.0,
        startAngle, startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(radiusX * math.cos(startAngle + sweepAngle) + center.dx,
        radiusY * math.sin(startAngle + sweepAngle) + center.dy);
  }

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
  @override
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    assert(offsetIsValid(arcEnd));
    assert(radiusIsValid(radius));
    // _currentX, _currentY are the coordinates of start point on path,
    // arcEnd is final point of arc.
    // rx,ry are the radii of the eclipse (semi-major/semi-minor axis)
    // largeArc is false if arc is spanning less than or equal to 180 degrees.
    // clockwise is false if arc sweeps through decreasing angles or true
    // if sweeping through increasing angles.
    // rotation is the angle from the x-axis of the current coordinate
    // system to the x-axis of the eclipse.

    double rx = radius.x.abs();
    double ry = radius.y.abs();

    // If the current point and target point for the arc are identical, it
    // should be treated as a zero length path. This ensures continuity in
    // animations.
    final bool isSamePoint = _currentX == arcEnd.dx && _currentY == arcEnd.dy;

    // If rx = 0 or ry = 0 then this arc is treated as a straight line segment
    // (a "lineto") joining the endpoints.
    // http://www.w3.org/TR/SVG/implnote.html#ArcOutOfRangeParameters
    if (isSamePoint || rx.toInt() == 0 || ry.toInt() == 0) {
      _commands.add(LineTo(arcEnd.dx, arcEnd.dy));
      _setCurrentPoint(arcEnd.dx, arcEnd.dy);
      return;
    }

    // As an intermediate point to finding center parametrization, place the
    // origin on the midpoint between start/end points and rotate to align
    // coordinate axis with axes of the ellipse.
    final double midPointX = (_currentX - arcEnd.dx) / 2.0;
    final double midPointY = (_currentY - arcEnd.dy) / 2.0;

    // Convert rotation or radians.
    final double xAxisRotation = math.pi * rotation / 180.0;

    // Cache cos/sin value.
    final double cosXAxisRotation = math.cos(xAxisRotation);
    final double sinXAxisRotation = math.sin(xAxisRotation);

    // Calculate rotate midpoint as x/yPrime.
    final double xPrime =
        (cosXAxisRotation * midPointX) + (sinXAxisRotation * midPointY);
    final double yPrime =
        (-sinXAxisRotation * midPointX) + (cosXAxisRotation * midPointY);

    // Check if the radii are big enough to draw the arc, scale radii if not.
    // http://www.w3.org/TR/SVG/implnote.html#ArcCorrectionOutOfRangeRadii
    double rxSquare = rx * rx;
    double rySquare = ry * ry;
    final double xPrimeSquare = xPrime * xPrime;
    final double yPrimeSquare = yPrime * yPrime;

    double radiiScale = (xPrimeSquare / rxSquare) + (yPrimeSquare / rySquare);
    if (radiiScale > 1) {
      radiiScale = math.sqrt(radiiScale);
      rx *= radiiScale;
      ry *= radiiScale;
      rxSquare = rx * rx;
      rySquare = ry * ry;
    }

    // Compute transformed center. eq. 5.2
    final double distanceSquare =
        (rxSquare * yPrimeSquare) + rySquare * xPrimeSquare;
    final double cNumerator = (rxSquare * rySquare) - distanceSquare;
    double scaleFactor = math.sqrt(math.max(cNumerator / distanceSquare, 0.0));
    if (largeArc == clockwise) {
      scaleFactor = -scaleFactor;
    }
    // Ready to compute transformed center.
    final double cxPrime = scaleFactor * ((rx * yPrime) / ry);
    final double cyPrime = scaleFactor * (-(ry * xPrime) / rx);

    // Rotate to find actual center.
    final double cx = cosXAxisRotation * cxPrime -
        sinXAxisRotation * cyPrime +
        ((_currentX + arcEnd.dx) / 2.0);
    final double cy = sinXAxisRotation * cxPrime +
        cosXAxisRotation * cyPrime +
        ((_currentY + arcEnd.dy) / 2.0);

    // Calculate start angle and sweep.
    // Start vector is from midpoint of start/end points to transformed center.
    final double startVectorX = (xPrime - cxPrime) / rx;
    final double startVectorY = (yPrime - cyPrime) / ry;

    final double startAngle = math.atan2(startVectorY, startVectorX);
    final double endVectorX = (-xPrime - cxPrime) / rx;
    final double endVectorY = (-yPrime - cyPrime) / ry;
    double sweepAngle = math.atan2(endVectorY, endVectorX) - startAngle;

    if (clockwise && sweepAngle < 0) {
      sweepAngle += math.pi * 2.0;
    } else if (!clockwise && sweepAngle > 0) {
      sweepAngle -= math.pi * 2.0;
    }

    _commands.add(Ellipse(cx, cy, rx, ry, xAxisRotation, startAngle,
        startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(arcEnd.dx, arcEnd.dy);
  }

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
  @override
  void relativeArcToPoint(
    ui.Offset arcEndDelta, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    assert(offsetIsValid(arcEndDelta));
    assert(radiusIsValid(radius));
    arcToPoint(
        ui.Offset(_currentX + arcEndDelta.dx, _currentY + arcEndDelta.dy),
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise);
  }

  /// Adds a new subpath that consists of four lines that outline the
  /// given rectangle.
  @override
  void addRect(ui.Rect rect) {
    assert(rectIsValid(rect));
    _openNewSubpath(rect.left, rect.top);
    _commands.add(RectCommand(rect.left, rect.top, rect.width, rect.height));
  }

  /// Adds a new subpath that consists of a curve that forms the
  /// ellipse that fills the given rectangle.
  ///
  /// To add a circle, pass an appropriate rectangle as `oval`.
  /// [Rect.fromCircle] can be used to easily describe the circle's center
  /// [Offset] and radius.
  @override
  void addOval(ui.Rect oval) {
    assert(rectIsValid(oval));
    final ui.Offset center = oval.center;
    final double radiusX = oval.width / 2;
    final double radiusY = oval.height / 2;

    /// At startAngle = 0, the path will begin at center + cos(0) * radius.
    _openNewSubpath(center.dx + radiusX, center.dy);
    _commands.add(Ellipse(
        center.dx, center.dy, radiusX, radiusY, 0.0, 0.0, 2 * math.pi, false));
  }

  /// Adds a new subpath with one arc segment that consists of the arc
  /// that follows the edge of the oval bounded by the given
  /// rectangle, from startAngle radians around the oval up to
  /// startAngle + sweepAngle radians around the oval, with zero
  /// radians being the point on the right hand side of the oval that
  /// crosses the horizontal line that intersects the center of the
  /// rectangle and with positive angles going clockwise around the
  /// oval.
  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    assert(rectIsValid(oval));
    final ui.Offset center = oval.center;
    final double radiusX = oval.width / 2;
    final double radiusY = oval.height / 2;
    _openNewSubpath(radiusX * math.cos(startAngle) + center.dx,
        radiusY * math.sin(startAngle) + center.dy);
    _commands.add(Ellipse(center.dx, center.dy, radiusX, radiusY, 0.0,
        startAngle, startAngle + sweepAngle, sweepAngle.isNegative));

    _setCurrentPoint(radiusX * math.cos(startAngle + sweepAngle) + center.dx,
        radiusY * math.sin(startAngle + sweepAngle) + center.dy);
  }

  /// Adds a new subpath with a sequence of line segments that connect the given
  /// points.
  ///
  /// If `close` is true, a final line segment will be added that connects the
  /// last point to the first point.
  ///
  /// The `points` argument is interpreted as offsets from the origin.
  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    assert(points != null);
    if (points.isEmpty) {
      return;
    }

    moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final ui.Offset point = points[i];
      lineTo(point.dx, point.dy);
    }
    if (close) {
      this.close();
    } else {
      _setCurrentPoint(points.last.dx, points.last.dy);
    }
  }

  /// Adds a new subpath that consists of the straight lines and
  /// curves needed to form the rounded rectangle described by the
  /// argument.
  @override
  void addRRect(ui.RRect rrect) {
    assert(rrectIsValid(rrect));

    // Set the current point to the top left corner of the rectangle (the
    // point on the top of the rectangle farthest to the left that isn't in
    // the rounded corner).
    // TODO(het): Is this the current point in Flutter?
    _openNewSubpath(rrect.tallMiddleRect.left, rrect.top);
    _commands.add(RRectCommand(rrect));
  }

  /// Adds a new subpath that consists of the given `path` offset by the given
  /// `offset`.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given offset. The matrix is a 4x4
  /// matrix stored in column major order.
  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    assert(path != null); // path is checked on the engine side
    assert(offsetIsValid(offset));
    if (matrix4 != null) {
      _addPathWithMatrix(path, offset.dx, offset.dy, toMatrix32(matrix4));
    } else {
      _addPath(path, offset.dx, offset.dy);
    }
  }

  void _addPath(SurfacePath path, double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) {
      subpaths.addAll(path.subpaths);
    } else {
      subpaths.addAll(path
          ._transform(Matrix4.translationValues(dx, dy, 0.0).storage)
          .subpaths);
    }
  }

  void _addPathWithMatrix(
      SurfacePath path, double dx, double dy, Float32List matrix) {
    assert(matrix4IsValid(matrix));
    final Matrix4 transform = Matrix4.fromFloat32List(matrix);
    transform.translate(dx, dy);
    subpaths.addAll(path._transform(transform.storage).subpaths);
  }

  /// Adds the given path to this path by extending the current segment of this
  /// path with the first segment of the given path.
  ///
  /// If `matrix4` is specified, the path will be transformed by this matrix
  /// after the matrix is translated by the given `offset`.  The matrix is a 4x4
  /// matrix stored in column major order.
  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    assert(path != null); // path is checked on the engine side
    assert(offsetIsValid(offset));
    if (matrix4 != null) {
      final Float32List matrix32 = toMatrix32(matrix4);
      assert(matrix4IsValid(matrix32));
      _extendWithPathAndMatrix(path, offset.dx, offset.dy, matrix32);
    } else {
      _extendWithPath(path, offset.dx, offset.dy);
    }
  }

  void _extendWithPath(SurfacePath path, double dx, double dy) {
    if (dx == 0.0 && dy == 0.0) {
      assert(path.subpaths.length == 1);
      _ensurePathStarted();
      _commands.addAll(path.subpaths.single.commands);
      _setCurrentPoint(
          path.subpaths.single.currentX, path.subpaths.single.currentY);
    } else {
      throw UnimplementedError('Cannot extend path with non-zero offset');
    }
  }

  void _extendWithPathAndMatrix(
      SurfacePath path, double dx, double dy, Float32List matrix) {
    throw UnimplementedError('Cannot extend path with transform matrix');
  }

  /// Closes the last subpath, as if a straight line had been drawn
  /// from the current point to the first point of the subpath.
  @override
  void close() {
    _ensurePathStarted();
    _commands.add(const CloseCommand());
    _setCurrentPoint(_currentSubpath.startX, _currentSubpath.startY);
  }

  /// Clears the [Path] object of all subpaths, returning it to the
  /// same state it had when it was created. The _current point_ is
  /// reset to the origin.
  @override
  void reset() {
    subpaths.clear();
  }

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
  @override
  bool contains(ui.Offset point) {
    assert(offsetIsValid(point));
    final int subPathCount = subpaths.length;
    if (subPathCount == 0) {
      return false;
    }
    final double pointX = point.dx;
    final double pointY = point.dy;
    if (subPathCount == 1) {
      // Optimize for rect/roundrect checks.
      final Subpath subPath = subpaths[0];
      if (subPath.commands.length == 1) {
        final PathCommand cmd = subPath.commands[0];
        if (cmd is RectCommand) {
          if (pointY < cmd.y || pointY > (cmd.y + cmd.height)) {
            return false;
          }
          if (pointX < cmd.x || pointX > (cmd.x + cmd.width)) {
            return false;
          }
          return true;
        } else if (cmd is RRectCommand) {
          final ui.RRect rRect = cmd.rrect;
          if (pointY < rRect.top || pointY > rRect.bottom) {
            return false;
          }
          if (pointX < rRect.left || pointX > rRect.right) {
            return false;
          }
          final double rRectWidth = rRect.width;
          final double rRectHeight = rRect.height;
          final double tlRadiusX = math.min(rRect.tlRadiusX, rRectWidth / 2.0);
          final double tlRadiusY = math.min(rRect.tlRadiusY, rRectHeight / 2.0);
          if (pointX < (rRect.left + tlRadiusX) &&
              pointY < (rRect.top + tlRadiusY)) {
            // Top left corner
            return _ellipseContains(pointX, pointY, rRect.left + tlRadiusX,
                rRect.top + tlRadiusY, tlRadiusX, tlRadiusY);
          }
          final double trRadiusX = math.min(rRect.trRadiusX, rRectWidth / 2.0);
          final double trRadiusY = math.min(rRect.trRadiusY, rRectHeight / 2.0);
          if (pointX >= (rRect.right - trRadiusX) &&
              pointY < (rRect.top + trRadiusY)) {
            // Top right corner
            return _ellipseContains(pointX, pointY, rRect.right - trRadiusX,
                rRect.top + trRadiusY, trRadiusX, trRadiusY);
          }
          final double brRadiusX = math.min(rRect.brRadiusX, rRectWidth / 2.0);
          final double brRadiusY = math.min(rRect.brRadiusY, rRectHeight / 2.0);
          if (pointX >= (rRect.right - brRadiusX) &&
              pointY >= (rRect.bottom - brRadiusY)) {
            // Bottom right corner
            return _ellipseContains(pointX, pointY, rRect.right - brRadiusX,
                rRect.bottom - brRadiusY, trRadiusX, trRadiusY);
          }
          final double blRadiusX = math.min(rRect.blRadiusX, rRectWidth / 2.0);
          final double blRadiusY = math.min(rRect.blRadiusY, rRectHeight / 2.0);
          if (pointX < (rRect.left + blRadiusX) &&
              pointY >= (rRect.bottom - blRadiusY)) {
            // Bottom left corner
            return _ellipseContains(pointX, pointY, rRect.left + blRadiusX,
                rRect.bottom - blRadiusY, trRadiusX, trRadiusY);
          }
          return true;
        }
        // TODO: For improved performance, handle Ellipse special case.
      }
    }
    final ui.Size size = window.physicalSize;
    // If device pixel ratio has changed we can't reuse prior raw recorder.
    if (_rawRecorder != null &&
        _rawRecorder._devicePixelRatio !=
            EngineWindow.browserDevicePixelRatio) {
      _rawRecorder = null;
    }
    final double dpr = window.devicePixelRatio;
    _rawRecorder ??=
        ui.RawRecordingCanvas(ui.Size(size.width / dpr, size.height / dpr));
    // Account for the shift due to padding.
    _rawRecorder.translate(-BitmapCanvas.kPaddingPixels.toDouble(),
        -BitmapCanvas.kPaddingPixels.toDouble());
    _rawRecorder.drawPath(
        this, (SurfacePaint()..color = const ui.Color(0xFF000000)).paintData);
    final double recorderDevicePixelRatio = _rawRecorder._devicePixelRatio;
    final bool result = _rawRecorder._canvasPool.context.isPointInPath(
        pointX * recorderDevicePixelRatio, pointY * recorderDevicePixelRatio);
    _rawRecorder.dispose();
    return result;
  }

  /// Returns a copy of the path with all the segments of every
  /// subpath translated by the given offset.
  @override
  SurfacePath shift(ui.Offset offset) {
    assert(offsetIsValid(offset));
    final List<Subpath> shiftedSubPaths = <Subpath>[];
    for (final Subpath subPath in subpaths) {
      shiftedSubPaths.add(subPath.shift(offset));
    }
    return SurfacePath._clone(shiftedSubPaths, fillType);
  }

  /// Returns a copy of the path with all the segments of every
  /// sub path transformed by the given matrix.
  @override
  SurfacePath transform(Float64List matrix4) {
    return _transform(toMatrix32(matrix4));
  }

  SurfacePath _transform(Float32List matrix) {
    assert(matrix4IsValid(matrix));
    final SurfacePath transformedPath = SurfacePath();
    for (final Subpath subPath in subpaths) {
      for (final PathCommand cmd in subPath.commands) {
        cmd.transform(matrix, transformedPath);
      }
    }
    return transformedPath;
  }

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
  @override
  ui.Rect getBounds() {
    // Sufficiently small number for curve eq.
    const double epsilon = 0.000000001;
    bool ltrbInitialized = false;
    double left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
    double curX = 0.0;
    double curY = 0.0;
    double minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0;
    for (Subpath subpath in subpaths) {
      for (PathCommand op in subpath.commands) {
        bool skipBounds = false;
        switch (op.type) {
          case PathCommandTypes.moveTo:
            final MoveTo cmd = op;
            curX = minX = maxX = cmd.x;
            curY = minY = maxY = cmd.y;
            break;
          case PathCommandTypes.lineTo:
            final LineTo cmd = op;
            curX = minX = maxX = cmd.x;
            curY = minY = maxY = cmd.y;
            break;
          case PathCommandTypes.ellipse:
            final Ellipse cmd = op;
            // Rotate 4 corners of bounding box.
            final double rx = cmd.radiusX;
            final double ry = cmd.radiusY;
            final double cosVal = math.cos(cmd.rotation);
            final double sinVal = math.sin(cmd.rotation);
            final double rxCos = rx * cosVal;
            final double ryCos = ry * cosVal;
            final double rxSin = rx * sinVal;
            final double rySin = ry * sinVal;

            final double leftDeltaX = rxCos - rySin;
            final double rightDeltaX = -rxCos - rySin;
            final double topDeltaY = ryCos + rxSin;
            final double bottomDeltaY = ryCos - rxSin;

            final double centerX = cmd.x;
            final double centerY = cmd.y;

            double rotatedX = centerX + leftDeltaX;
            double rotatedY = centerY + topDeltaY;
            minX = maxX = rotatedX;
            minY = maxY = rotatedY;

            rotatedX = centerX + rightDeltaX;
            rotatedY = centerY + bottomDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            rotatedX = centerX - leftDeltaX;
            rotatedY = centerY - topDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            rotatedX = centerX - rightDeltaX;
            rotatedY = centerY - bottomDeltaY;
            minX = math.min(minX, rotatedX);
            maxX = math.max(maxX, rotatedX);
            minY = math.min(minY, rotatedY);
            maxY = math.max(maxY, rotatedY);

            curX = centerX + cmd.radiusX;
            curY = centerY;
            break;
          case PathCommandTypes.quadraticCurveTo:
            final QuadraticCurveTo cmd = op;
            final double x1 = curX;
            final double y1 = curY;
            final double cpX = cmd.x1;
            final double cpY = cmd.y1;
            final double x2 = cmd.x2;
            final double y2 = cmd.y2;

            minX = math.min(x1, x2);
            minY = math.min(y1, y2);
            maxX = math.max(x1, x2);
            maxY = math.max(y1, y2);

            // Curve equation : (1-t)(1-t)P1 + 2t(1-t)CP + t*t*P2.
            // At extrema's derivative = 0.
            // Solve for
            // -2x1+2tx1 + 2cpX + 4tcpX + 2tx2 = 0
            // -2x1 + 2cpX +2t(x1 + 2cpX + x2) = 0
            // t = (x1 - cpX) / (x1 - 2cpX + x2)

            double denom = x1 - (2 * cpX) + x2;
            if (denom.abs() > epsilon) {
              final num t1 = (x1 - cpX) / denom;
              if ((t1 >= 0) && (t1 <= 1.0)) {
                // Solve (x,y) for curve at t = tx to find extrema
                final num tprime = 1.0 - t1;
                final num extremaX = (tprime * tprime * x1) +
                    (2 * t1 * tprime * cpX) +
                    (t1 * t1 * x2);
                final num extremaY = (tprime * tprime * y1) +
                    (2 * t1 * tprime * cpY) +
                    (t1 * t1 * y2);
                // Expand bounds.
                minX = math.min(minX, extremaX);
                maxX = math.max(maxX, extremaX);
                minY = math.min(minY, extremaY);
                maxY = math.max(maxY, extremaY);
              }
            }
            // Now calculate dy/dt = 0
            denom = y1 - (2 * cpY) + y2;
            if (denom.abs() > epsilon) {
              final num t2 = (y1 - cpY) / denom;
              if ((t2 >= 0) && (t2 <= 1.0)) {
                final num tprime2 = 1.0 - t2;
                final num extrema2X = (tprime2 * tprime2 * x1) +
                    (2 * t2 * tprime2 * cpX) +
                    (t2 * t2 * x2);
                final num extrema2Y = (tprime2 * tprime2 * y1) +
                    (2 * t2 * tprime2 * cpY) +
                    (t2 * t2 * y2);
                // Expand bounds.
                minX = math.min(minX, extrema2X);
                maxX = math.max(maxX, extrema2X);
                minY = math.min(minY, extrema2Y);
                maxY = math.max(maxY, extrema2Y);
              }
            }
            curX = x2;
            curY = y2;
            break;
          case PathCommandTypes.bezierCurveTo:
            final BezierCurveTo cmd = op;
            final double startX = curX;
            final double startY = curY;
            final double cpX1 = cmd.x1;
            final double cpY1 = cmd.y1;
            final double cpX2 = cmd.x2;
            final double cpY2 = cmd.y2;
            final double endX = cmd.x3;
            final double endY = cmd.y3;
            // Bounding box is defined by all points on the curve where
            // monotonicity changes.
            minX = math.min(startX, endX);
            minY = math.min(startY, endY);
            maxX = math.max(startX, endX);
            maxY = math.max(startY, endY);

            double extremaX;
            double extremaY;
            double a, b, c;

            // Check for simple case of strong ordering before calculating
            // extrema
            if (!(((startX < cpX1) && (cpX1 < cpX2) && (cpX2 < endX)) ||
                ((startX > cpX1) && (cpX1 > cpX2) && (cpX2 > endX)))) {
              // The extrema point is dx/dt B(t) = 0
              // The derivative of B(t) for cubic bezier is a quadratic equation
              // with multiple roots
              // B'(t) = a*t*t + b*t + c*t
              a = -startX + (3 * (cpX1 - cpX2)) + endX;
              b = 2 * (startX - (2 * cpX1) + cpX2);
              c = -startX + cpX1;

              // Now find roots for quadratic equation with known coefficients
              // a,b,c
              // The roots are (-b+-sqrt(b*b-4*a*c)) / 2a
              num s = (b * b) - (4 * a * c);
              // If s is negative, we have no real roots
              if ((s >= 0.0) && (a.abs() > epsilon)) {
                if (s == 0.0) {
                  // we have only 1 root
                  final num t = -b / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);
                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                } else {
                  // we have 2 roots
                  s = math.sqrt(s);
                  num t = (-b - s) / (2 * a);
                  num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);
                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                  // check 2nd root
                  t = (-b + s) / (2 * a);
                  tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaX = ((tprime * tprime * tprime) * startX) +
                        ((3 * tprime * tprime * t) * cpX1) +
                        ((3 * tprime * t * t) * cpX2) +
                        (t * t * t * endX);

                    minX = math.min(extremaX, minX);
                    maxX = math.max(extremaX, maxX);
                  }
                }
              }
            }

            // Now calc extremes for dy/dt = 0 just like above
            if (!(((startY < cpY1) && (cpY1 < cpY2) && (cpY2 < endY)) ||
                ((startY > cpY1) && (cpY1 > cpY2) && (cpY2 > endY)))) {
              // The extrema point is dy/dt B(t) = 0
              // The derivative of B(t) for cubic bezier is a quadratic equation
              // with multiple roots
              // B'(t) = a*t*t + b*t + c*t
              a = -startY + (3 * (cpY1 - cpY2)) + endY;
              b = 2 * (startY - (2 * cpY1) + cpY2);
              c = -startY + cpY1;

              // Now find roots for quadratic equation with known coefficients
              // a,b,c
              // The roots are (-b+-sqrt(b*b-4*a*c)) / 2a
              num s = (b * b) - (4 * a * c);
              // If s is negative, we have no real roots
              if ((s >= 0.0) && (a.abs() > epsilon)) {
                if (s == 0.0) {
                  // we have only 1 root
                  final num t = -b / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaY = ((tprime * tprime * tprime) * startY) +
                        ((3 * tprime * tprime * t) * cpY1) +
                        ((3 * tprime * t * t) * cpY2) +
                        (t * t * t * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                } else {
                  // we have 2 roots
                  s = math.sqrt(s);
                  final num t = (-b - s) / (2 * a);
                  final num tprime = 1.0 - t;
                  if ((t >= 0.0) && (t <= 1.0)) {
                    extremaY = ((tprime * tprime * tprime) * startY) +
                        ((3 * tprime * tprime * t) * cpY1) +
                        ((3 * tprime * t * t) * cpY2) +
                        (t * t * t * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                  // check 2nd root
                  final num t2 = (-b + s) / (2 * a);
                  final num tprime2 = 1.0 - t2;
                  if ((t2 >= 0.0) && (t2 <= 1.0)) {
                    extremaY = ((tprime2 * tprime2 * tprime2) * startY) +
                        ((3 * tprime2 * tprime2 * t2) * cpY1) +
                        ((3 * tprime2 * t2 * t2) * cpY2) +
                        (t2 * t2 * t2 * endY);
                    minY = math.min(extremaY, minY);
                    maxY = math.max(extremaY, maxY);
                  }
                }
              }
            }
            break;
          case PathCommandTypes.rect:
            final RectCommand cmd = op;
            left = cmd.x;
            double width = cmd.width;
            if (cmd.width < 0) {
              left -= width;
              width = -width;
            }
            double top = cmd.y;
            double height = cmd.height;
            if (cmd.height < 0) {
              top -= height;
              height = -height;
            }
            curX = minX = left;
            maxX = left + width;
            curY = minY = top;
            maxY = top + height;
            break;
          case PathCommandTypes.rRect:
            final RRectCommand cmd = op;
            final ui.RRect rRect = cmd.rrect;
            curX = minX = rRect.left;
            maxX = rRect.left + rRect.width;
            curY = minY = rRect.top;
            maxY = rRect.top + rRect.height;
            break;
          case PathCommandTypes.close:
          default:
            skipBounds = false;
            break;
        }
        if (!skipBounds) {
          if (!ltrbInitialized) {
            left = minX;
            right = maxX;
            top = minY;
            bottom = maxY;
            ltrbInitialized = true;
          } else {
            left = math.min(left, minX);
            right = math.max(right, maxX);
            top = math.min(top, minY);
            bottom = math.max(bottom, maxY);
          }
        }
      }
    }
    return ltrbInitialized
        ? ui.Rect.fromLTRB(left, top, right, bottom)
        : ui.Rect.zero;
  }

  /// Creates a [PathMetrics] object for this path.
  ///
  /// If `forceClosed` is set to true, the contours of the path will be measured
  /// as if they had been closed, even if they were not explicitly closed.
  @override
  SurfacePathMetrics computeMetrics({bool forceClosed = false}) {
    return SurfacePathMetrics._(this, forceClosed);
  }

  /// Detects if path is rounded rectangle and returns rounded rectangle or
  /// null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  ui.RRect get webOnlyPathAsRoundedRect {
    if (subpaths.length != 1) {
      return null;
    }
    final Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final PathCommand command = subPath.commands[0];
    return (command is RRectCommand) ? command.rrect : null;
  }

  /// Detects if path is simple rectangle and returns rectangle or null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  ui.Rect get webOnlyPathAsRect {
    if (subpaths.length != 1) {
      return null;
    }
    final Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final PathCommand command = subPath.commands[0];
    return (command is RectCommand)
        ? ui.Rect.fromLTWH(command.x, command.y, command.width, command.height)
        : null;
  }

  /// Detects if path is simple oval and returns [Ellipse] or null.
  ///
  /// Used for web optimization of physical shape represented as
  /// a persistent div.
  Ellipse get webOnlyPathAsCircle {
    if (subpaths.length != 1) {
      return null;
    }
    final Subpath subPath = subpaths[0];
    if (subPath.commands.length != 1) {
      return null;
    }
    final PathCommand command = subPath.commands[0];
    if (command is Ellipse) {
      final Ellipse ellipse = command;
      if ((ellipse.endAngle - ellipse.startAngle) % (2 * math.pi) == 0.0) {
        return ellipse;
      }
    }
    return null;
  }

  /// Serializes this path to a value that's sent to a CSS custom painter for
  /// painting.
  List<dynamic> webOnlySerializeToCssPaint() {
    final List<dynamic> serializedSubpaths = <dynamic>[];
    for (int i = 0; i < subpaths.length; i++) {
      serializedSubpaths.add(subpaths[i].serializeToCssPaint());
    }
    return serializedSubpaths;
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'Path(${subpaths.join(', ')})';
    } else {
      return super.toString();
    }
  }
}

// Returns true if point is inside ellipse.
bool _ellipseContains(double px, double py, double centerX, double centerY,
    double radiusX, double radiusY) {
  final double dx = px - centerX;
  final double dy = py - centerY;
  return ((dx * dx) / (radiusX * radiusX)) + ((dy * dy) / (radiusY * radiusY)) <
      1.0;
}
