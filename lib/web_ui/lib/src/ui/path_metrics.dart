// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

/// An iterable collection of [PathMetric] objects describing a [Path].
///
/// A [PathMetrics] object is created by using the [Path.computeMetrics] method,
/// and represents the path as it stood at the time of the call. Subsequent
/// modifications of the path do not affect the [PathMetrics] object.
///
/// Each path metric corresponds to a segment, or contour, of a path.
///
/// For example, a path consisting of a [Path.lineTo], a [Path.moveTo], and
/// another [Path.lineTo] will contain two contours and thus be represented by
/// two [PathMetric] objects.
///
/// When iterating across a [PathMetrics]' contours, the [PathMetric] objects
/// are only valid until the next one is obtained.
class PathMetrics extends collection.IterableBase<PathMetric> {
  PathMetrics._(Path path, bool forceClosed)
      : _iterator = PathMetricIterator._(PathMetric._(path, forceClosed));

  final Iterator<PathMetric> _iterator;

  @override
  Iterator<PathMetric> get iterator => _iterator;
}

/// Tracks iteration from one segment of a path to the next for measurement.
class PathMetricIterator implements Iterator<PathMetric> {
  PathMetricIterator._(this._pathMetric);

  PathMetric _pathMetric;
  bool _firstTime = true;

  @override
  PathMetric get current =>
      _firstTime ? null : _pathMetric._segments.isEmpty ? null : _pathMetric;

  @override
  bool moveNext() {
    // PathMetric isn't a normal iterable - it's already initialized to its
    // first Path.  Should only call _moveNext when done with the first one.
    if (_firstTime == true) {
      _firstTime = false;
      return _pathMetric._segments.isNotEmpty;
    } else if (_pathMetric?._moveNext() == true) {
      return true;
    }
    _pathMetric = null;
    return false;
  }
}

// Maximum range value used in curve subdivision using Casteljau algorithm.
const int _kMaxTValue = 0x3FFFFFFF;
// Distance at which we stop subdividing cubic and quadratic curves.
const double _fTolerance = 0.5;

/// Utilities for measuring a [Path] and extracting subpaths.
///
/// Iterate over the object returned by [Path.computeMetrics] to obtain
/// [PathMetric] objects.
///
/// Once created, metrics will only be valid while the iterator is at the given
/// contour. When the next contour's [PathMetric] is obtained, this object
/// becomes invalid.
///
/// Implementation is based on
/// https://github.com/google/skia/blob/master/src/core/SkContourMeasure.cpp
/// to maintain consistency with native platforms.
class PathMetric {
  final Path _path;
  final bool _forceClosed;

  // If the contour ends with a call to [Path.close] (which may
  // have been implied when using [Path.addRect])
  bool _isClosed;
  // Iterator index into [Path.subPaths]
  int _subPathIndex = 0;
  List<_PathSegment> _segments;
  double _contourLength;

  /// Create a new empty [Path] object.
  PathMetric._(this._path, this._forceClosed) {
    _buildSegments();
  }

  /// Return the total length of the current contour.
  double get length => _contourLength;

  /// Computes the position of hte current contour at the given offset, and the
  /// angle of the path at that point.
  ///
  /// For example, calling this method with a distance of 1.41 for a line from
  /// 0.0,0.0 to 2.0,2.0 would give a point 1.0,1.0 and the angle 45 degrees
  /// (but in radians).
  ///
  /// Returns null if the contour has zero [length].
  ///
  /// The distance is clamped to the [length] of the current contour.
  Tangent getTangentForOffset(double distance) {
    final Float32List posTan = _getPosTan(distance);
    // first entry == 0 indicates that Skia returned false
    if (posTan[0] == 0.0) {
      return null;
    } else {
      return Tangent(
          Offset(posTan[1], posTan[2]), Offset(posTan[3], posTan[4]));
    }
  }

  Float32List _getPosTan(double distance) => throw UnimplementedError();

  /// Given a start and stop distance, return the intervening segment(s).
  ///
  /// `start` and `end` are pinned to legal values (0..[length])
  /// Returns null if the segment is 0 length or `start` > `stop`.
  /// Begin the segment with a moveTo if `startWithMoveTo` is true.
  Path extractPath(double start, double end, {bool startWithMoveTo = true}) =>
      throw UnimplementedError();

  /// Whether the contour is closed.
  ///
  /// Returns true if the contour ends with a call to [Path.close] (which may
  /// have been implied when using [Path.addRect]) or if `forceClosed` was
  /// specified as true in the call to [Path.computeMetrics].  Returns false
  /// otherwise.
  bool get isClosed {
    return _isClosed;
  }

  // Move to the next contour in the path.
  //
  // A path can have a next contour if [Path.moveTo] was called after drawing
  // began. Return true if one exists, or false.
  //
  // This is not exactly congruent with a regular [Iterator.moveNext].
  // Typically, [Iterator.moveNext] should be called before accessing the
  // [Iterator.current]. In this case, the [PathMetric] is valid before
  // calling `_moveNext` - `_moveNext` should be called after the first
  // iteration is done instead of before.
  bool _moveNext() {
    if (_subPathIndex == (_path.subpaths.length - 1)) {
      return false;
    }
    ++_subPathIndex;
    _buildSegments();
    return true;
  }

  void _buildSegments() {
    _segments = <_PathSegment>[];
    _isClosed = false;
    double distance = 0.0;
    int pointIndex = -1;
    bool haveSeenMoveTo = false;
    bool haveSeenClose = false;

    if (_path.subpaths.isEmpty) {
      _contourLength = 0;
      return;
    }
    final engine.Subpath subpath = _path.subpaths[_subPathIndex];
    final List<engine.PathCommand> commands = subpath.commands;
    double currentX = 0.0, currentY = 0.0;
    final Function lineToHandler = (double x, double y) {
      final double dx = currentX - x;
      final double dy = currentY - y;
      final double prevDistance = distance;
      distance += math.sqrt(dx * dx + dy * dy);
      // As we accumulate distance, we have to check that the result of +=
      // actually made it larger, since a very small delta might be > 0, but
      // still have no effect on distance (if distance >>> delta).
      if (distance > prevDistance) {
        _segments.add(_PathSegment(engine.PathCommandTypes.lineTo, distance,
            [currentX, currentY, x, y]));
      }
      currentX = x;
      currentY = y;
    };
    _EllipseSegmentResult ellipseResult;
    for (engine.PathCommand command in commands) {
      switch (command.type) {
        case engine.PathCommandTypes.moveTo:
          final engine.MoveTo moveTo = command;
          currentX = moveTo.x;
          currentY = moveTo.y;
          haveSeenMoveTo = true;
          break;
        case engine.PathCommandTypes.lineTo:
          assert(haveSeenMoveTo);
          final engine.LineTo lineTo = command;
          lineToHandler(lineTo.x, lineTo.y);
          break;
        case engine.PathCommandTypes.bezierCurveTo:
          assert(haveSeenMoveTo);
          final engine.BezierCurveTo curve = command;
          // Compute cubic curve distance.
          distance = _computeCubicSegments(
              currentX,
              currentY,
              curve.x1,
              curve.y1,
              curve.x2,
              curve.y2,
              curve.x3,
              curve.y3,
              distance,
              0,
              _kMaxTValue,
              _segments);
          break;
        case engine.PathCommandTypes.quadraticCurveTo:
          assert(haveSeenMoveTo);
          final engine.QuadraticCurveTo quadraticCurveTo = command;
          // Compute quad curve distance.
          distance = _computeQuadSegments(
              currentX,
              currentY,
              quadraticCurveTo.x1,
              quadraticCurveTo.y1,
              quadraticCurveTo.x2,
              quadraticCurveTo.y2,
              distance,
              0,
              _kMaxTValue);
          break;
        case engine.PathCommandTypes.close:
          haveSeenClose = true;
          break;
        case engine.PathCommandTypes.ellipse:
          final engine.Ellipse ellipse = command;
          ellipseResult ??= _EllipseSegmentResult();
          _computeEllipseSegments(
              currentX,
              currentY,
              distance,
              ellipse.x,
              ellipse.y,
              ellipse.startAngle,
              ellipse.endAngle,
              ellipse.rotation,
              ellipse.radiusX,
              ellipse.radiusY,
              ellipse.anticlockwise,
              ellipseResult,
              _segments);
          distance = ellipseResult.distance;
          currentX = ellipseResult.endPointX;
          currentY = ellipseResult.endPointY;
          _isClosed = true;
          break;
        case engine.PathCommandTypes.rRect:
          final engine.RRectCommand rrectCommand = command;
          final RRect rrect = rrectCommand.rrect;
          engine.RRectMetricsRenderer(moveToCallback: (double x, double y) {
            currentX = x;
            currentY = y;
            _isClosed = true;
            haveSeenMoveTo = true;
          }, lineToCallback: (double x, double y) {
            lineToHandler(x, y);
          }, ellipseCallback: (double centerX,
              double centerY,
              double radiusX,
              double radiusY,
              double rotation,
              double startAngle,
              double endAngle,
              bool antiClockwise) {
            ellipseResult ??= _EllipseSegmentResult();
            _computeEllipseSegments(
                currentX,
                currentY,
                distance,
                centerX,
                centerY,
                startAngle,
                endAngle,
                rotation,
                radiusX,
                radiusY,
                antiClockwise,
                ellipseResult,
                _segments);
            distance = ellipseResult.distance;
            currentX = ellipseResult.endPointX;
            currentY = ellipseResult.endPointY;
          }).render(rrect);
          _isClosed = true;
          break;
        case engine.PathCommandTypes.rect:
          final engine.RectCommand rectCommand = command;
          final double x = rectCommand.x;
          final double y = rectCommand.y;
          final double width = rectCommand.width;
          final double height = rectCommand.height;
          currentX = x;
          currentY = y;
          lineToHandler(x + width, y);
          lineToHandler(x + width, y + height);
          lineToHandler(x, y + height);
          lineToHandler(x, y);
          _isClosed = true;
          break;
        default:
          throw UnimplementedError('Unknown path command $command');
      }
    }
    if (!_isClosed && _forceClosed && _segments.isNotEmpty) {
      _PathSegment firstSegment = _segments.first;
      lineToHandler(firstSegment.points[0], firstSegment.points[1]);
    }
    _contourLength = distance;
  }

  static bool _tspanBigEnough(int tSpan) => (tSpan >> 10) != 0;

  static bool _cubicTooCurvy(double x0, double y0, double x1, double y1,
      double x2, double y2, double x3, double y3) {
    // Measure distance from start-end line at 1/3 and 2/3rds to control
    // points. If distance is less than _fTolerance we should continue
    // subdividing curve. Uses approx distance for speed.
    //
    // p1 = point 1/3rd between start,end points.
    final double p1x = (x0 * 2 / 3) + (x3 / 3);
    final double p1y = (y0 * 2 / 3) + (y3 / 3);
    if ((p1x - x1).abs() > _fTolerance) {
      return true;
    }
    if ((p1y - y1).abs() > _fTolerance) {
      return true;
    }
    // p2 = point 2/3rd between start,end points.
    final double p2x = (x0 / 3) + (x3 * 2 / 3);
    final double p2y = (y0 / 3) + (y3 * 2 / 3);
    if ((p2x - x2).abs() > _fTolerance) {
      return true;
    }
    if ((p2y - y2).abs() > _fTolerance) {
      return true;
    }
    return false;
  }

  // Recursively subdivides cubic and adds segments.
  static double _computeCubicSegments(
      double x0,
      double y0,
      double x1,
      double y1,
      double x2,
      double y2,
      double x3,
      double y3,
      double distance,
      int tMin,
      int tMax,
      List<_PathSegment> segments) {
    if (_tspanBigEnough(tMax - tMin) &&
        _cubicTooCurvy(x0, y0, x1, y1, x2, y2, x3, y3)) {
      // Chop cubic into two halves (De Cateljau's algorithm)
      // See https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
      final double abX = (x0 + x1) / 2;
      final double abY = (y0 + y1) / 2;
      final double bcX = (x1 + x2) / 2;
      final double bcY = (y1 + y2) / 2;
      final double cdX = (x2 + x3) / 2;
      final double cdY = (y2 + y3) / 2;
      final double abcX = (abX + bcX) / 2;
      final double abcY = (abY + bcY) / 2;
      final double bcdX = (bcX + cdX) / 2;
      final double bcdY = (bcY + cdY) / 2;
      final double abcdX = (abcX + bcdX) / 2;
      final double abcdY = (abcY + bcdY) / 2;
      final int tHalf = (tMin + tMax) >> 1;
      distance = _computeCubicSegments(
          x0, y0, abX, abY, abcX, abcY, abcdX, abcdY, distance, tMin, tHalf, segments);
      distance = _computeCubicSegments(
          abcdX, abcdY, bcdX, bcdY, cdX, cdY, x3, y3, distance, tHalf, tMax, segments);
    } else {
      final double dx = x0 - x3;
      final double dy = y0 - y3;
      final double startToEndDistance = math.sqrt(dx * dx + dy * dy);
      final double prevDistance = distance;
      distance += startToEndDistance;
      if (distance > prevDistance) {
        segments.add(_PathSegment(engine.PathCommandTypes.bezierCurveTo,
            distance, <double>[x0, y0, x1, y1, x2, y2, x3, y3]));
      }
    }
    return distance;
  }

  static bool _quadTooCurvy(
      double x0, double y0, double x1, double y1, double x2, double y2) {
    // (a/4 + b/2 + c/4) - (a/2 + c/2)  =  -a/4 + b/2 - c/4
    final double dx = (x1 / 2) - (x0 + x2) / 4;
    if (dx.abs() > _fTolerance) {
      return true;
    }
    final double dy = (y1 / 2) - (y0 + y2) / 4;
    if (dy.abs() > _fTolerance) {
      return true;
    }
    return false;
  }

  double _computeQuadSegments(double x0, double y0, double x1, double y1,
      double x2, double y2, double distance, int tMin, int tMax) {
    if (_tspanBigEnough(tMax - tMin) && _quadTooCurvy(x0, y0, x1, y1, x2, y2)) {
      final double p01x = (x0 + x1) / 2;
      final double p01y = (y0 + y1) / 2;
      final double p12x = (x1 + x2) / 2;
      final double p12y = (y1 + y2) / 2;
      final double p012x = (p01x + p12x) / 2;
      final double p012y = (p01y + p12y) / 2;
      final int tHalf = (tMin + tMax) >> 1;
      distance = _computeQuadSegments(
          x0, y0, p01x, p01y, p012x, p012y, distance, tMin, tHalf);
      distance = _computeQuadSegments(
          p012x, p012y, p12x, p12y, x2, y2, distance, tMin, tHalf);
    } else {
      final double dx = x0 - x2;
      final double dy = y0 - y2;
      final double startToEndDistance = math.sqrt(dx * dx + dy * dy);
      final double prevDistance = distance;
      distance += startToEndDistance;
      if (distance > prevDistance) {
        _segments.add(_PathSegment(engine.PathCommandTypes.quadraticCurveTo,
            distance, <double>[x0, y0, x1, y1, x2, y2]));
      }
    }
    return distance;
  }

  // Create segments by converting arc to cubics.
  // See http://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter.
  static void _computeEllipseSegments(
      double startX,
      double startY,
      double distance,
      double cx,
      double cy,
      double startAngle,
      double endAngle,
      double rotation,
      double radiusX,
      double radiusY,
      bool anticlockwise,
      _EllipseSegmentResult result,
      List<_PathSegment> segments) {
    final double endX = cx + (radiusX * math.cos(endAngle));
    final double endY = cy + (radiusY * math.sin(endAngle));
    result.endPointX = endX;
    result.endPointY = endY;
    // Check for http://www.w3.org/TR/SVG/implnote.html#ArcOutOfRangeParameters
    // Treat as line segment from start to end if arc has zero radii.
    // If start and end point are the same treat as zero length path.
    if ((radiusX == 0 || radiusY == 0) || (startX == endX && startY == endY)) {
      result.distance = distance;
      return;
    }
    final double rxAbs = radiusX.abs();
    final double ryAbs = radiusY.abs();

    final double theta1 = startAngle;
    final double theta2 = endAngle;
    final double thetaArc = theta2 - theta1;

    // Add 0.01f to make sure we have enough segments when thetaArc is close
    // to pi/2.
    final int numSegments = (thetaArc / ((math.pi / 2.0) + 0.01)).abs().ceil();
    double x0 = startX;
    double y0 = startY;
    for (int segmentIndex = 0; segmentIndex < numSegments; segmentIndex++) {
      final double startTheta =
          theta1 + (segmentIndex * thetaArc / numSegments);
      final double endTheta =
          theta1 + ((segmentIndex + 1) * thetaArc / numSegments);
      final double t = (4.0 / 3.0) * math.tan((endTheta - startTheta) / 4);
      if (!t.isFinite) {
        result.distance = distance;
        return;
      }
      final double sinStartTheta = math.sin(startTheta);
      final double cosStartTheta = math.cos(startTheta);
      final double sinEndTheta = math.sin(endTheta);
      final double cosEndTheta = math.cos(endTheta);

      // Compute cubic segment start, control point and end (target).
      final double p1x = rxAbs * (cosStartTheta - t * sinStartTheta) + cx;
      final double p1y = ryAbs * (sinStartTheta + t * cosStartTheta) + cy;
      final double targetPointX = rxAbs * cosEndTheta + cx;
      final double targetPointY = ryAbs * sinEndTheta + cy;
      final double p2x = targetPointX + rxAbs * (t * sinEndTheta);
      final double p2y = targetPointY + ryAbs * (-t * cosEndTheta);

      distance = _computeCubicSegments(x0, y0, p1x, p1y, p2x, p2y, targetPointX,
          targetPointY, distance, 0, _kMaxTValue, segments);
      x0 = targetPointX;
      y0 = targetPointY;
    }
    result.distance = distance;
  }

  @override
  String toString() => 'PathMetric';
}

class _EllipseSegmentResult {
  double endPointX;
  double endPointY;
  double distance;
  _EllipseSegmentResult();
}

class _PathSegment {
  _PathSegment(this.segmentType, this.distance, this.points);

  final int segmentType;
  final double distance;
  final List<double> points;
}

/// The geometric description of a tangent: the angle at a point.
///
/// See also:
///  * [PathMetric.getTangentForOffset], which returns the tangent of an offset
///    along a path.
class Tangent {
  /// Creates a [Tangent] with the given values.
  ///
  /// The arguments must not be null.
  const Tangent(this.position, this.vector)
      : assert(position != null),
        assert(vector != null);

  /// Creates a [Tangent] based on the angle rather than the vector.
  ///
  /// The [vector] is computed to be the unit vector at the given angle,
  /// interpreted as clockwise radians from the x axis.
  factory Tangent.fromAngle(Offset position, double angle) {
    return Tangent(position, Offset(math.cos(angle), math.sin(angle)));
  }

  /// Position of the tangent.
  ///
  /// When used with [PathMetric.getTangentForOffset], this represents the
  /// precise position that the given offset along the path corresponds to.
  final Offset position;

  /// The vector of the curve at [position].
  ///
  /// When used with [PathMetric.getTangentForOffset], this is the vector of the
  /// curve that is at the given offset along the path (i.e. the direction of
  /// the curve at [position]).
  final Offset vector;

  /// The direction of the curve at [position].
  ///
  /// When used with [PathMetric.getTangentForOffset], this is the angle of the
  /// curve that is the given offset along the path (i.e. the direction of the
  /// curve at [position]).
  ///
  /// This value is in radians, with 0.0 meaning pointing along the x axis in
  /// the positive x-axis direction, positive numbers pointing downward toward
  /// the negative y-axis, i.e. in a clockwise direction, and negative numbers
  /// pointing upward toward the positive y-axis, i.e. in a counter-clockwise
  /// direction.
  // flip the sign to be consistent with [Path.arcTo]'s `sweepAngle`
  double get angle => -math.atan2(vector.dy, vector.dx);
}
