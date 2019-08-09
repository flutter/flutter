// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Converts conic curve to a list of quadratic curves for rendering on
/// canvas or conversion to svg.
///
/// See "High order approximation of conic sections by quadratic splines"
/// by Michael Floater, 1993.
/// Skia implementation reference:
/// https://github.com/google/skia/blob/master/src/core/SkGeometry.cpp
class Conic {
  double p0x, p0y, p1x, p1y, p2x, p2y;
  final double fW;
  static const int _maxSubdivisionCount = 5;

  Conic(this.p0x, this.p0y, this.p1x, this.p1y, this.p2x, this.p2y, this.fW);

  /// Returns array of points for the approximation of the conic as quad(s).
  ///
  /// First offset is start Point. Each pair of offsets after are quadratic
  /// control and end points.
  List<ui.Offset> toQuads() {
    final List<ui.Offset> pointList = <ui.Offset>[];
    // This value specifies error bound.
    const double conicTolerance = 1.0 / 4.0;

    // Based on error bound, compute how many times we should subdivide
    final int subdivideCount = _computeSubdivisionCount(conicTolerance);

    // Split conic into quads, writes quad coordinates into [_pointList] and
    // returns number of quads.
    assert(subdivideCount > 0);
    int quadCount = 1 << subdivideCount;
    bool skipSubdivide = false;
    pointList.add(ui.Offset(p0x, p0y));
    if (subdivideCount == _maxSubdivisionCount) {
      // We have an extreme number of quads, chop this conic and check if
      // it generates a pair of lines, in which case we should not subdivide.
      final List<Conic> dst = List<Conic>(2);
      _chop(dst);
      final Conic conic0 = dst[0];
      final Conic conic1 = dst[1];
      // If this chop generates pair of lines no need to subdivide.
      if (conic0.p1x == conic0.p2x &&
          conic0.p1y == conic0.p2y &&
          conic1.p0x == conic1.p1x &&
          conic1.p0y == conic1.p1y) {
        final ui.Offset controlPointOffset = ui.Offset(conic0.p1x, conic0.p1y);
        pointList.add(controlPointOffset);
        pointList.add(controlPointOffset);
        pointList.add(controlPointOffset);
        pointList.add(ui.Offset(conic1.p2x, conic1.p2y));
        quadCount = 2;
        skipSubdivide = true;
      }
    }
    if (!skipSubdivide) {
      _subdivide(this, subdivideCount, pointList);
    }

    // If there are any non-finite generated points, pin to middle of hull.
    final int pointCount = 2 * quadCount + 1;
    bool hasNonFinitePoints = false;
    for (int p = 0; p < pointCount; ++p) {
      if (pointList[p].dx.isNaN || pointList[p].dy.isNaN) {
        hasNonFinitePoints = true;
        break;
      }
    }
    if (hasNonFinitePoints) {
      for (int p = 1; p < pointCount - 1; ++p) {
        pointList[p] = ui.Offset(p1x, p1y);
      }
    }
    return pointList;
  }

  static bool _between(double a, double b, double c) {
    return (a - b) * (c - b) <= 0;
  }

  // Subdivides a conic and writes to points list.
  static void _subdivide(Conic src, int level, List<ui.Offset> pointList) {
    assert(level >= 0);
    if (0 == level) {
      // At lowest subdivision point, copy control point and end point to
      // target.
      pointList.add(ui.Offset(src.p1x, src.p1y));
      pointList.add(ui.Offset(src.p2x, src.p2y));
      return;
    }
    final List<Conic> dst = List<Conic>(2);
    src._chop(dst);
    final Conic conic0 = dst[0];
    final Conic conic1 = dst[1];
    final double startY = src.p0y;
    final double endY = src.p2y;
    final double cpY = src.p1y;
    if (_between(startY, cpY, endY)) {
      // Ensure that chopped conics maintain their y-order.
      final double midY = conic0.p2y;
      if (!_between(startY, midY, endY)) {
        // The computed midpoint is outside end points, move it to
        // closer one.
        final double closerY =
            (midY - startY).abs() < (midY - endY).abs() ? startY : endY;
        conic0.p2y = conic1.p0y = closerY;
      }
      if (!_between(startY, conic0.p1y, conic0.p2y)) {
        // First control point not between start and end points, move it
        // to start.
        conic0.p1y = startY;
      }
      if (!_between(conic1.p0y, conic1.p1y, endY)) {
        // Second control point not between start and end points, move it
        // to end.
        conic1.p1y = endY;
      }
      // Verify that conics points are ordered.
      assert(_between(startY, conic0.p1y, conic0.p2y));
      assert(_between(conic0.p1y, conic0.p2y, conic1.p1y));
      assert(_between(conic0.p2y, conic1.p1y, endY));
    }
    --level;
    _subdivide(conic0, level, pointList);
    _subdivide(conic1, level, pointList);
  }

  static double _subdivideWeightValue(double w) {
    return math.sqrt(0.5 + w * 0.5);
  }

  // Splits conic into 2 parts based on weight.
  void _chop(List<Conic> dst) {
    final double scale = 1.0 / (1.0 + fW);
    final double newW = _subdivideWeightValue(fW);
    final ui.Offset wp1 = ui.Offset(fW * p1x, fW * p1y);
    ui.Offset m = ui.Offset((p0x + (2 * wp1.dx) + p2x) * scale * 0.5,
        (p0y + 2 * wp1.dy + p2y) * scale * 0.5);
    if (m.dx.isNaN || m.dy.isNaN) {
      final double w2 = fW * 2;
      final double scaleHalf = 1.0 / (1 + fW) * 0.5;
      m = ui.Offset((p0x + (w2 * p1x) + p2x) * scaleHalf,
          (p0y + (w2 * p1y) + p2y) * scaleHalf);
    }
    dst[0] = Conic(p0x, p0y, (p0x + wp1.dx) * scale, (p0y + wp1.dy) * scale,
        m.dx, m.dy, newW);
    dst[1] = Conic(m.dx, m.dy, (p2x + wp1.dx) * scale, (p2y + wp1.dy) * scale,
        p2x, p2y, newW);
  }

  /// Computes number of binary subdivisions of the curve given
  /// the tolerance.
  ///
  /// The number of subdivisions never exceed [_maxSubdivisionCount].
  int _computeSubdivisionCount(double tolerance) {
    assert(tolerance.isFinite);
    // Expecting finite coordinates.
    assert(p0x.isFinite &&
        p1x.isFinite &&
        p2x.isFinite &&
        p0y.isFinite &&
        p1y.isFinite &&
        p2y.isFinite);
    if (tolerance < 0) {
      return 0;
    }
    // See "High order approximation of conic sections by quadratic splines"
    // by Michael Floater, 1993.
    // Error bound e0 = |a| |p0 - 2p1 + p2| / 4(2 + a).
    final double a = fW - 1;
    final double k = a / (4.0 * (2.0 + a));
    final double x = k * (p0x - 2 * p1x + p2x);
    final double y = k * (p0y - 2 * p1y + p2y);

    double error = math.sqrt(x * x + y * y);
    int pow2 = 0;
    for (; pow2 < _maxSubdivisionCount; ++pow2) {
      if (error <= tolerance) {
        break;
      }
      error *= 0.25;
    }
    return pow2;
  }
}
