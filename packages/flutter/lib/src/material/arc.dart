// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show hashValues, lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// How close the begin and end points must be to an axis to be considered
// vertical or horizontal.
const double _kOnAxisDelta = 2.0;

/// A [Tween] that animates an [Offset] along a circular arc.
///
/// The arc's radius is related to the bounding box that contains the [begin]
/// and [end] points. If the bounding box is taller than it is wide, then the
/// center of the circle will be horizontally aligned with the end point.
/// Otherwise the center of the circle will be aligned with the begin point.
/// The arc's sweep is always less than or equal to 90 degrees.
///
/// Unlike those of most Tweens, the [begin] and [end] members of a
/// [MaterialPointArcTween] are immutable.
///
/// See also:
///
/// * [MaterialRectArcTween]
class MaterialPointArcTween extends Tween<Offset> {
  /// Creates a [Tween] for animating [Offset]s along a circular arc.
  ///
  /// The [begin] and [end] points are required, cannot be null, and are
  /// immutable.
  MaterialPointArcTween({
    @required Offset begin,
    @required Offset end
  }) : super(begin: begin, end: end) {
    assert(begin != null);
    assert(end != null);
    // An explanation with a diagram can be found at https://goo.gl/vMSdRg
    final Offset delta = end - begin;
    final double deltaX = delta.dx.abs();
    final double deltaY = delta.dy.abs();
    final double distanceFromAtoB = delta.distance;
    final Offset c = new Offset(end.dx, begin.dy);

    double sweepAngle() => 2.0 * math.asin(distanceFromAtoB / (2.0 * _radius));

    if (deltaX > _kOnAxisDelta && deltaY > _kOnAxisDelta) {
      if (deltaX < deltaY) {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - begin).distance / 2.0;
        _center = new Offset(end.dx + _radius * (begin.dx - end.dx).sign, end.dy);
        if (begin.dx < end.dx) {
          _beginAngle = sweepAngle() * (begin.dy - end.dy).sign;
          _endAngle = 0.0;
        } else {
          _beginAngle = math.PI + sweepAngle() * (end.dy - begin.dy).sign;
          _endAngle = math.PI;
        }
      } else {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - end).distance / 2.0;
        _center = new Offset(begin.dx, begin.dy + (end.dy - begin.dy).sign * _radius);
        if (begin.dy < end.dy) {
          _beginAngle = -math.PI / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (end.dx - begin.dx).sign;
        } else {
          _beginAngle = math.PI / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (begin.dx - end.dx).sign;
        }
      }
    }
  }

  Offset _center;
  double _radius;
  double _beginAngle;
  double _endAngle;

  /// The center of the circular arc, null if [begin] and [end] are horiztonally or
  /// vertically aligned.
  Offset get center => _center;

  /// The radius of the circular arc, null if begin and end are horiztonally or
  /// vertically aligned.
  double get radius => _radius;

  /// The beginning of the arc's sweep in radians, measured from the positive X axis.
  /// Positive angles turn clockwise. Null if begin and end are horiztonally or
  /// vertically aligned.
  double get beginAngle => _beginAngle;

  /// The end of the arc's sweep in radians, measured from the positive X axis.
  /// Positive angles turn clockwise.
  double get endAngle => _beginAngle;

  /// Setting the arc's [begin] parameter is not supported. Construct a new arc instead.
  @override
  set begin(Offset value) {
    assert(false); // not supported
  }

  /// Setting the arc's [end] parameter is not supported. Construct a new arc instead.
  @override
  set end(Offset value) {
    assert(false); // not supported
  }

  @override
  Offset lerp(double t) {
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    if (_beginAngle == null || _endAngle == null)
      return Offset.lerp(begin, end, t);
    final double angle = lerpDouble(_beginAngle, _endAngle, t);
    final double x = math.cos(angle) * _radius;
    final double y = math.sin(angle) * _radius;
    return _center + new Offset(x, y);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! MaterialPointArcTween)
      return false;
    final MaterialPointArcTween typedOther = other;
    return begin == typedOther.begin
        && end == typedOther.end;
  }

  @override
  int get hashCode => hashValues(begin, end);

  @override
  String toString() {
    return '$runtimeType($begin \u2192 $end center=$center, radius=$radius, beginAngle=$beginAngle, endAngle=$endAngle)';
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

const List<_Diagonal> _allDiagonals = const <_Diagonal>[
  const _Diagonal(_CornerId.topLeft, _CornerId.bottomRight),
  const _Diagonal(_CornerId.bottomRight, _CornerId.topLeft),
  const _Diagonal(_CornerId.topRight, _CornerId.bottomLeft),
  const _Diagonal(_CornerId.bottomLeft, _CornerId.topRight),
];

typedef dynamic _KeyFunc<T>(T input);

// Select the element for which the key function returns the maximum value.
T _maxBy<T>(Iterable<T> input, _KeyFunc<T> keyFunc) {
  T maxValue;
  dynamic maxKey;
  for (T value in input) {
    final dynamic key = keyFunc(value);
    if (maxKey == null || key > maxKey) {
      maxValue = value;
      maxKey = key;
    }
  }
  return maxValue;
}

/// A [Tween] that animates a [Rect] from [begin] to [end].
///
/// The rectangle corners whose diagonal is closest to the overall direction of
/// the animation follow arcs defined with [MaterialPointArcTween].
///
/// Unlike those of most Tweens, the [begin] and [end] members of a
/// [MaterialPointArcTween] are immutable.
///
/// See also:
///
/// * [MaterialPointArcTween]. the analogue for [Offset] interporation.
/// * [RectTween], which does a linear rectangle interpolation.
class MaterialRectArcTween extends RectTween {
  /// Creates a [Tween] for animating [Rect]s along a circular arc.
  ///
  /// The [begin] and [end] points are required, cannot be null, and are
  /// immutable.
  MaterialRectArcTween({
    @required Rect begin,
    @required Rect end
  }) : super(begin: begin, end: end) {
    assert(begin != null);
    assert(end != null);
    final Offset centersVector = end.center - begin.center;
    _diagonal = _maxBy<_Diagonal>(_allDiagonals, (_Diagonal d) => _diagonalSupport(centersVector, d));
    _beginArc = new MaterialPointArcTween(
      begin: _cornerFor(begin, _diagonal.beginId),
      end: _cornerFor(end, _diagonal.beginId)
    );
    _endArc = new MaterialPointArcTween(
      begin: _cornerFor(begin, _diagonal.endId),
      end: _cornerFor(end, _diagonal.endId)
    );
  }

  _Diagonal _diagonal;
  MaterialPointArcTween _beginArc;
  MaterialPointArcTween _endArc;

  Offset _cornerFor(Rect rect, _CornerId id) {
    switch (id) {
      case _CornerId.topLeft: return rect.topLeft;
      case _CornerId.topRight: return rect.topRight;
      case _CornerId.bottomLeft: return rect.bottomLeft;
      case _CornerId.bottomRight: return rect.bottomRight;
    }
    return Offset.zero;
  }

  double _diagonalSupport(Offset centersVector, _Diagonal diagonal) {
    final Offset delta = _cornerFor(begin, diagonal.endId) - _cornerFor(begin, diagonal.beginId);
    final double length = delta.distance;
    return centersVector.dx * delta.dx / length + centersVector.dy * delta.dy / length;
  }

  /// The path of the corresponding [begin], [end] rectangle corners that lead
  /// the animation.
  MaterialPointArcTween get beginArc => _beginArc;

  /// The path of the corresponding [begin], [end] rectangle corners that trail
  /// the animation.
  MaterialPointArcTween get endArc => _endArc;

  /// Setting the arc's [begin] parameter is not supported. Construct a new arc instead.
  @override
  set begin(Rect value) {
    assert(false); // not supported
  }

  /// Setting the arc's [end] parameter is not supported. Construct a new arc instead.
  @override
  set end(Rect value) {
    assert(false); // not supported
  }

  @override
  Rect lerp(double t) {
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return new Rect.fromPoints(_beginArc.lerp(t), _endArc.lerp(t));
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! MaterialRectArcTween)
      return false;
    final MaterialRectArcTween typedOther = other;
    return begin == typedOther.begin
        && end == typedOther.end;
  }

  @override
  int get hashCode => hashValues(begin, end);

  @override
  String toString() {
    return '$runtimeType($begin \u2192 $end beginArc=$beginArc, endArc=$endArc)';
  }
}
