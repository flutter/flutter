// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Computes winding number and onCurveCount for a path and point.
class PathWinding {
  PathWinding(this.pathRef, this.x, this.y) {
    _walkPath();
  }

  final PathRef pathRef;
  final double x;
  final double y;
  int _w = 0;
  int _onCurveCount = 0;

  int get w => _w;

  int get onCurveCount => _onCurveCount;

  /// Buffer used for max(iterator result, chopped 3 cubics).
  final Float32List _buffer = Float32List(8 + 10);

  /// Iterates through path and computes winding.
  void _walkPath() {
    final PathIterator iter = PathIterator(pathRef, true);
    int verb;
    while ((verb = iter.next(_buffer)) != SPath.kDoneVerb) {
      switch (verb) {
        case SPath.kMoveVerb:
        case SPath.kCloseVerb:
          break;
        case SPath.kLineVerb:
          _computeLineWinding();
          break;
        case SPath.kQuadVerb:
          _computeQuadWinding();
          break;
        case SPath.kConicVerb:
          _computeConicWinding(pathRef._conicWeights![iter._conicWeightIndex]);
          break;
        case SPath.kCubicVerb:
          _computeCubicWinding();
          break;
      }
    }
  }

  void _computeLineWinding() {
    final double x0 = _buffer[0];
    final double startY = _buffer[1];
    double y0 = startY;
    final double x1 = _buffer[2];
    final double endY = _buffer[3];
    double y1 = endY;
    final double dy = y1 - y0;
    int dir = 1;
    // Swap so that y0 <= y1 holds.
    if (y0 > y1) {
      double temp = y0;
      y0 = y1;
      y1 = temp;
      dir = -1;
    }
    // If point is outside top/bottom bounds, winding is 0.
    if (y < y0 || y > y1) {
      return;
    }
    if (_checkOnCurve(x, y, x0, startY, x1, endY)) {
      _onCurveCount++;
      return;
    }
    if (y == y1) {
      return;
    }
    // c = ax*by − ay*bx where a is the line and b is line formed from start
    // to the given point(x,y).
    final double crossProduct = (x1 - x0) * (y - startY) - dy * (x - x0);
    if (crossProduct == 0) {
      // zero cross means the point is on the line, and since the case where
      // y of the query point is at the end point is handled above, we can be
      // sure that we're on the line (excluding the end point) here.
      if (x != x1 || y != endY) {
        _onCurveCount++;
      }
      dir = 0;
    } else if (SPath.scalarSignedAsInt(crossProduct) == dir) {
      // Direction of cross product and line the same.
      dir = 0;
    }
    _w += dir;
  }

  // Check if point starts the line, handle special case for horizontal lines
  // where and point except the end point is considered on curve.
  static bool _checkOnCurve(double x, double y, double startX, double startY,
      double endX, double endY) {
    if (startY == endY) {
      // Horizontal line.
      return SPath.between(startX, x, endX) && x != endX;
    } else {
      return x == startX && y == startY;
    }
  }

  void _computeQuadWinding() {
    // Check if we need to chop quadratic at extrema to compute 2 separate
    // windings.
    int n = 0;
    if (!_isQuadMonotonic(_buffer)) {
      n = _chopQuadAtExtrema(_buffer);
    }
    int winding = _computeMonoQuadWinding(
        _buffer[0], _buffer[1], _buffer[2], _buffer[3], _buffer[4], _buffer[5]);
    if (n > 0) {
      winding += _computeMonoQuadWinding(_buffer[4], _buffer[5], _buffer[6],
          _buffer[7], _buffer[8], _buffer[9]);
    }
    _w += winding;
  }

  int _computeMonoQuadWinding(
      double x0, double y0, double x1, double y1, double x2, double y2) {
    int dir = 1;
    final double startY = y0;
    final double endY = y2;
    if (y0 > y2) {
      final double temp = y0;
      y0 = y2;
      y2 = temp;
      dir = -1;
    }
    if (y < y0 || y > y2) {
      return 0;
    }
    if (_checkOnCurve(x, y, x0, startY, x2, endY)) {
      _onCurveCount++;
      return 0;
    }
    if (y == y2) {
      return 0;
    }

    _QuadRoots quadRoots = _QuadRoots();
    final int n = quadRoots.findRoots(
        startY - 2 * y1 + endY, 2 * (y1 - startY), startY - y);
    assert(n <= 1);
    double xt;
    if (0 == n) {
      // zero roots are returned only when y0 == y
      xt = dir == 1 ? x0 : x2;
    } else {
      final double t = quadRoots.root0!;
      final double C = x0;
      final double A = x2 - 2 * x1 + C;
      final double B = 2 * (x1 - C);
      xt = polyEval(A, B, C, t);
    }
    if (_nearlyEqual(xt, x)) {
      if (x != x2 || y != endY) {
        // don't test end points; they're start points
        _onCurveCount += 1;
        return 0;
      }
    }
    return xt < x ? dir : 0;
  }

  /// Chops a non-monotonic quadratic curve, returns subdivisions and writes
  /// result into [buffer].
  static int _chopQuadAtExtrema(Float32List buffer) {
    final double x0 = buffer[0];
    final double y0 = buffer[1];
    final double x1 = buffer[2];
    final double y1 = buffer[3];
    final double x2 = buffer[4];
    final double y2 = buffer[5];
    double? tValueAtExtrema = _validUnitDivide(y0 - y1, y0 - y1 - y1 + y2);
    if (tValueAtExtrema != null) {
      // Chop quad at t value by interpolating along p0-p1 and p1-p2.
      double p01x = x0 + (tValueAtExtrema * (x1 - x0));
      double p01y = y0 + (tValueAtExtrema * (y1 - y0));
      double p12x = x1 + (tValueAtExtrema * (x2 - x1));
      double p12y = y1 + (tValueAtExtrema * (y2 - y1));
      double cx = p01x + (tValueAtExtrema * (p12x - p01x));
      double cy = p01y + (tValueAtExtrema * (p12y - p01y));
      buffer[2] = p01x;
      buffer[3] = p01y;
      buffer[4] = cx;
      buffer[5] = cy;
      buffer[6] = p12x;
      buffer[7] = p12y;
      buffer[8] = x2;
      buffer[9] = y2;
      return 1;
    }
    // if we get here, we need to force output to be monotonic, even though
    // we couldn't compute a unit divide value (probably underflow).
    buffer[3] = (y0 - y1).abs() < (y1 - y2).abs() ? y0 : y2;
    return 0;
  }

  static bool _isQuadMonotonic(Float32List quad) {
    final double y0 = quad[1];
    final double y1 = quad[3];
    final double y2 = quad[5];
    if (y0 == y1) {
      return true;
    }
    if (y0 < y1) {
      return y1 <= y2;
    } else {
      return y1 >= y2;
    }
  }

  void _computeConicWinding(double weight) {
    Conic conic = Conic(_buffer[0], _buffer[1], _buffer[2], _buffer[3],
        _buffer[4], _buffer[5], weight);
    // If the data points are very large, the conic may not be monotonic but may also
    // fail to chop. Then, the chopper does not split the original conic in two.
    bool isMono = _isQuadMonotonic(_buffer);
    List<Conic> conics = [];
    conic.chopAtYExtrema(conics);
    _computeMonoConicWinding(conics[0]);
    if (!isMono && conics.length == 2) {
      _computeMonoConicWinding(conics[1]);
    }
  }

  void _computeMonoConicWinding(Conic conic) {
    double y0 = conic.p0y;
    double y2 = conic.p2y;
    int dir = 1;
    if (y0 > y2) {
      final double swap = y0;
      y0 = y2;
      y2 = swap;
      dir = -1;
    }
    if (y < y0 || y > y2) {
      return;
    }
    if (_checkOnCurve(x, y, conic.p0x, conic.p0y, conic.p2x, conic.p2y)) {
      _onCurveCount += 1;
      return;
    }
    if (y == y2) {
      return;
    }

    double A = conic.p2y;
    double B = conic.p1y * conic.fW - y * conic.fW + y;
    double C = conic.p0y;
    // A = a + c - 2*(b*w - yCept*w + yCept)
    A += C - 2 * B;
    // B = b*w - w * yCept + yCept - a
    B -= C;
    C -= y;
    final _QuadRoots quadRoots = _QuadRoots();
    int n = quadRoots.findRoots(A, 2 * B, C);
    assert(n <= 1);
    double xt;
    if (0 == n) {
      // zero roots are returned only when y0 == y
      // Need [0] if dir == 1
      // and  [2] if dir == -1
      xt = dir == 1 ? conic.p0x : conic.p2x;
    } else {
      final double root = quadRoots.root0!;
      xt =
          _conicEvalNumerator(conic.p0x, conic.p1x, conic.p2x, conic.fW, root) /
              _conicEvalDenominator(conic.fW, root);
    }
    if (_nearlyEqual(xt, x)) {
      if (x != conic.p2x || y != conic.p2y) {
        // don't test end points; they're start points
        _onCurveCount += 1;
        return;
      }
    }
    _w += xt < x ? dir : 0;
  }

  void _computeCubicWinding() {
    int n = _chopCubicAtYExtrema(_buffer, _buffer);
    for (int i = 0; i <= n; ++i) {
      _windingMonoCubic(i * 3 * 2);
    }
  }

  void _windingMonoCubic(int bufferIndex) {
    final int bufferStartPos = bufferIndex;
    final double px0 = _buffer[bufferIndex++];
    final double py0 = _buffer[bufferIndex++];
    final double px1 = _buffer[bufferIndex++];
    bufferIndex++;
    final double px2 = _buffer[bufferIndex++];
    bufferIndex++;
    final double px3 = _buffer[bufferIndex++];
    final double py3 = _buffer[bufferIndex++];

    double y0 = py0;
    double y3 = py3;

    int dir = 1;
    if (y0 > y3) {
      final double swap = y0;
      y0 = y3;
      y3 = swap;
      dir = -1;
    }
    if (y < y0 || y > y3) {
      return;
    }
    if (_checkOnCurve(x, y, px0, py0, px3, py3)) {
      _onCurveCount += 1;
      return;
    }
    if (y == y3) {
      return;
    }

    // Quickly reject or accept
    final double min = math.min(px0, math.min(px1, math.min(px2, px3)));
    final double max = math.max(px0, math.max(px1, math.max(px2, px3)));
    if (x < min) {
      return;
    }
    if (x > max) {
      _w += dir;
      return;
    }
    // Compute the actual x(t) value.
    double? t = _chopMonoAtY(_buffer, bufferStartPos, y);
    if (t == null) {
      return;
    }
    double xt = _evalCubicPts(px0, px1, px2, px3, t);
    if (_nearlyEqual(xt, x)) {
      if (x != px3 || y != py3) {
        // don't test end points; they're start points
        _onCurveCount += 1;
        return;
      }
    }
    _w += xt < x ? dir : 0;
  }
}

// Iterates through path including generating closing segments.
class PathIterator {
  PathIterator(this.pathRef, bool forceClose)
      : _forceClose = forceClose,
        _verbCount = pathRef.countVerbs() {
    _pointIndex = 0;
    if (!pathRef.isFinite) {
      // Don't allow iteration through non-finite points, prepare to return
      // done verb.
      _verbIndex = pathRef.countVerbs();
    }
  }

  final PathRef pathRef;
  final bool _forceClose;
  final int _verbCount;

  bool _needClose = false;
  int _segmentState = SPathSegmentState.kEmptyContour;
  int _conicWeightIndex = -1;
  double _lastPointX = 0;
  double _lastPointY = 0;
  double _moveToX = 0;
  double _moveToY = 0;
  int _verbIndex = 0;
  int _pointIndex = 0;

  /// Maximum buffer size required for points in [next] calls.
  static const int kMaxBufferSize = 8;

  /// Returns true if first contour on path is closed.
  bool isClosedContour() {
    if (_verbCount == 0 || _verbIndex == _verbCount) {
      return false;
    }
    if (_forceClose) {
      return true;
    }
    int verbIndex = 0;
    // Skip starting moveTo.
    if (pathRef.atVerb(verbIndex) == SPath.kMoveVerb) {
      ++verbIndex;
    }
    while (verbIndex < _verbCount) {
      int verb = pathRef.atVerb(verbIndex++);
      if (SPath.kMoveVerb == verb) {
        break;
      }
      if (SPath.kCloseVerb == verb) {
        return true;
      }
    }
    return false;
  }

  int _autoClose(Float32List outPts) {
    if (_lastPointX != _moveToX || _lastPointY != _moveToY) {
      // Handle special case where comparison above will return true for
      // NaN != NaN although it should be false.
      if (_lastPointX.isNaN ||
          _lastPointY.isNaN ||
          _moveToX.isNaN ||
          _moveToY.isNaN) {
        return SPath.kCloseVerb;
      }
      outPts[0] = _lastPointX;
      outPts[1] = _lastPointY;
      outPts[2] = _moveToX;
      outPts[3] = _moveToY;
      _lastPointX = _moveToX;
      _lastPointY = _moveToY;
      return SPath.kLineVerb;
    } else {
      outPts[0] = _moveToX;
      outPts[1] = _moveToY;
      return SPath.kCloseVerb;
    }
  }

  // Returns true if caller should use moveTo, false if last point of
  // previous primitive.
  ui.Offset _constructMoveTo() {
    if (_segmentState == SPathSegmentState.kAfterMove) {
      // Set the first return point to move point.
      _segmentState = SPathSegmentState.kAfterPrimitive;
      return ui.Offset(_moveToX, _moveToY);
    }
    return ui.Offset(
        pathRef.points[_pointIndex - 2], pathRef.points[_pointIndex - 1]);
  }

  int peek() {
    if (_verbIndex < pathRef.countVerbs()) {
      return pathRef._fVerbs[_verbIndex];
    }
    if (_needClose && _segmentState == SPathSegmentState.kAfterPrimitive) {
      return (_lastPointX != _moveToX || _lastPointY != _moveToY)
          ? SPath.kLineVerb
          : SPath.kCloseVerb;
    }
    return SPath.kDoneVerb;
  }

  // Returns next verb and reads associated points into [outPts].
  int next(Float32List outPts) {
    if (_verbIndex == pathRef.countVerbs()) {
      // Close the curve if requested and if there is some curve to close
      if (_needClose && _segmentState == SPathSegmentState.kAfterPrimitive) {
        if (SPath.kLineVerb == _autoClose(outPts)) {
          return SPath.kLineVerb;
        }
        _needClose = false;
        return SPath.kCloseVerb;
      }
      return SPath.kDoneVerb;
    }
    int verb = pathRef._fVerbs[_verbIndex++];
    switch (verb) {
      case SPath.kMoveVerb:
        if (_needClose) {
          // Move back one verb.
          _verbIndex--;
          final int autoVerb = _autoClose(outPts);
          if (autoVerb == SPath.kCloseVerb) {
            _needClose = false;
          }
          return autoVerb;
        }
        if (_verbIndex == _verbCount) {
          return SPath.kDoneVerb;
        }
        double offsetX = pathRef.points[_pointIndex++];
        double offsetY = pathRef.points[_pointIndex++];
        _moveToX = offsetX;
        _moveToY = offsetY;
        outPts[0] = offsetX;
        outPts[1] = offsetY;
        _segmentState = SPathSegmentState.kAfterMove;
        _lastPointX = _moveToX;
        _lastPointY = _moveToY;
        _needClose = _forceClose;
        break;
      case SPath.kLineVerb:
        final ui.Offset start = _constructMoveTo();
        double offsetX = pathRef.points[_pointIndex++];
        double offsetY = pathRef.points[_pointIndex++];
        outPts[0] = start.dx;
        outPts[1] = start.dy;
        outPts[2] = offsetX;
        outPts[3] = offsetY;
        _lastPointX = offsetX;
        _lastPointY = offsetY;
        break;
      case SPath.kConicVerb:
        _conicWeightIndex++;
        final ui.Offset start = _constructMoveTo();
        outPts[0] = start.dx;
        outPts[1] = start.dy;
        outPts[2] = pathRef.points[_pointIndex++];
        outPts[3] = pathRef.points[_pointIndex++];
        _lastPointX = outPts[4] = pathRef.points[_pointIndex++];
        _lastPointY = outPts[5] = pathRef.points[_pointIndex++];
        break;
      case SPath.kQuadVerb:
        final ui.Offset start = _constructMoveTo();
        outPts[0] = start.dx;
        outPts[1] = start.dy;
        outPts[2] = pathRef.points[_pointIndex++];
        outPts[3] = pathRef.points[_pointIndex++];
        _lastPointX = outPts[4] = pathRef.points[_pointIndex++];
        _lastPointY = outPts[5] = pathRef.points[_pointIndex++];
        break;
      case SPath.kCubicVerb:
        final ui.Offset start = _constructMoveTo();
        outPts[0] = start.dx;
        outPts[1] = start.dy;
        outPts[2] = pathRef.points[_pointIndex++];
        outPts[3] = pathRef.points[_pointIndex++];
        outPts[4] = pathRef.points[_pointIndex++];
        outPts[5] = pathRef.points[_pointIndex++];
        _lastPointX = outPts[6] = pathRef.points[_pointIndex++];
        _lastPointY = outPts[7] = pathRef.points[_pointIndex++];
        break;
      case SPath.kCloseVerb:
        verb = _autoClose(outPts);
        if (verb == SPath.kLineVerb) {
          // Move back one verb since we constructed line for this close verb.
          _verbIndex--;
        } else {
          _needClose = false;
          _segmentState = SPathSegmentState.kEmptyContour;
        }
        _lastPointX = _moveToX;
        _lastPointY = _moveToY;
        break;
      case SPath.kDoneVerb:
        assert(_verbIndex == pathRef.countVerbs());
        break;
      default:
        throw FormatException('Unsupport Path verb $verb');
    }
    return verb;
  }

  double get conicWeight => pathRef.atWeight(_conicWeightIndex);
}
