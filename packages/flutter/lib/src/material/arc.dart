// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart'; // @required definition

abstract class _MaterialArc<T> {
  _MaterialArc({ this.begin, this.end });

  final T begin;
  final T end;

  T transform(double t);
}

class MaterialPointArc extends _MaterialArc<Point> {
  MaterialPointArc({
    @required Point begin,
    @required Point end
  }) : super(begin: begin, end: end) {
    // An explanation with a diagram can be found at https://goo.gl/vMSdRg
    final Offset delta = end - begin;
    final double deltaX = delta.dx.abs();
    final double deltaY = delta.dy.abs();
    final double distanceFromAtoB = delta.distance;
    final Point c = new Point(end.x, begin.y);

    double sweepAngle() => 2.0 *  math.asin(distanceFromAtoB / (2.0 * _radius));

    if (deltaX > 2.0 && deltaY > 2.0) {
      if (deltaX < deltaY) {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - begin).distance / 2.0;
        _center = new Point(end.x + _radius * (begin.x - end.x).sign, end.y);
        if (begin.x < end.x) {
          _beginAngle = sweepAngle() * (begin.y - end.y).sign;
          _endAngle = 0.0;
        } else {
          _beginAngle = math.PI + sweepAngle() * (end.y - begin.y).sign;
          _endAngle = math.PI;
        }
      } else {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - end).distance / 2.0;
        _center = new Point(begin.x, begin.y + (end.y - begin.y).sign * _radius);
        if (begin.y < end.y) {
          _beginAngle = -math.PI / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (end.x - begin.x).sign;
        } else {
          _beginAngle = math.PI / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (begin.x - end.x).sign;
        }
      }
    }
  }

  Point _center;
  double _radius;
  double _beginAngle;
  double _endAngle;

  @override
  Point transform(double t) {
    if (_beginAngle == null || _endAngle == null)
      return Point.lerp(begin, end, t);
    final double angle = lerpDouble(_beginAngle, _endAngle, t);
    final double x = math.cos(angle) * _radius;
    final double y = math.sin(angle) * _radius;
    return  _center + new Offset(x, y);
  }
}

enum _CornerId {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
}

class _Diagonal {
  const _Diagonal(this.beginId, this.endId);
  final _CornerId beginId;
  final _CornerId endId;
}

class MaterialRectArc extends _MaterialArc<Rect> {
  static final List<_Diagonal> _allDiagonals = <_Diagonal>[
    const _Diagonal(_CornerId.topLeft, _CornerId.bottomRight),
    const _Diagonal(_CornerId.bottomRight, _CornerId.topLeft),
    const _Diagonal(_CornerId.topRight, _CornerId.bottomLeft),
    const _Diagonal(_CornerId.bottomLeft, _CornerId.topRight),
  ];

  MaterialRectArc({
    @required Rect begin,
    @required Rect end
  }) : super(begin: begin, end: end) {
    final Offset centersVector = end.center - begin.center;
    double maxSupport = 0.0;
    for (_Diagonal diagonal in _allDiagonals) {
      final double support = _diagonalSupport(centersVector, diagonal);
      if (support > maxSupport) {
        _diagonal = diagonal;
        maxSupport = support;
      }
    }
    _beginArc = new MaterialPointArc(
      begin: _cornerFor(begin, _diagonal.beginId),
      end: _cornerFor(end, _diagonal.beginId)
    );
    _endArc = new MaterialPointArc(
      begin: _cornerFor(begin, _diagonal.endId),
      end: _cornerFor(end, _diagonal.endId)
    );
  }

  _Diagonal _diagonal;
  MaterialPointArc _beginArc;
  MaterialPointArc _endArc;

  Point _cornerFor(Rect rect, _CornerId id) {
    switch (id) {
      case _CornerId.topLeft: return rect.topLeft;
      case _CornerId.topRight: return rect.topRight;
      case _CornerId.bottomLeft: return rect.bottomLeft;
      case _CornerId.bottomRight: return rect.bottomRight;
    }
    return Point.origin;
  }

  double _diagonalSupport(Offset centersVector, _Diagonal diagonal) {
    final Offset delta = _cornerFor(begin, diagonal.endId) - _cornerFor(begin, diagonal.beginId);
    final double length = delta.distance;
    return centersVector.dx * delta.dx / length + centersVector.dy * delta.dy / length;
  }

  @override
  Rect transform(double t) {
    Point beginArcPoint = _beginArc.transform(t);
    Point endArcPoint = _endArc.transform(t);
    double minX = math.min(beginArcPoint.x, endArcPoint.x);
    double maxX = math.max(beginArcPoint.x, endArcPoint.x);
    double minY = math.min(beginArcPoint.y, endArcPoint.y);
    double maxY = math.max(beginArcPoint.y, endArcPoint.y);
    return new Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class MaterialPointArcTween extends Tween<Point> {
  MaterialPointArcTween({
    @required Point begin,
    @required Point end
  }) : _arc = new MaterialPointArc(begin: begin, end: end), super(begin: begin, end: end);

  final MaterialPointArc _arc;

  @override
  Point lerp(double t) => _arc.transform(t);
}

class MaterialRectArcTween extends Tween<Rect> {
  MaterialRectArcTween({
    @required Rect begin,
    @required Rect end
  }) : _arc = new MaterialRectArc(begin: begin, end: end), super(begin: begin, end: end);

  final MaterialRectArc _arc;

  @override
  Rect lerp(double t) => _arc.transform(t);
}
