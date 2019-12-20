// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

/// An easing curve, i.e. a mapping of the unit interval to the unit interval.
///
/// Easing curves are used to adjust the rate of change of an animation over
/// time, allowing them to speed up and slow down, rather than moving at a
/// constant rate.
///
/// A curve must map t=0.0 to 0.0 and t=1.0 to 1.0.
///
/// See also:
///
///  * [Curves], a collection of common animation easing curves.
///  * [CurveTween], which can be used to apply a [Curve] to an [Animation].
///  * [Canvas.drawArc], which draws an arc, and has nothing to do with easing
///    curves.
///  * [Animatable], for a more flexible interface that maps fractions to
///    arbitrary values.
@immutable
abstract class Curve {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Curve();

  /// Returns the value of the curve at point `t`.
  ///
  /// This function must ensure the following:
  /// - The value of `t` must be between 0.0 and 1.0
  /// - Values of `t`=0.0 and `t`=1.0 must be mapped to 0.0 and 1.0,
  /// respectively.
  ///
  /// It is recommended that subclasses override [transformInternal] instead of
  /// this function, as the above cases are already handled in the default
  /// implementation of [transform], which delegates the remaining logic to
  /// [transformInternal].
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return transformInternal(t);
  }

  /// Returns the value of the curve at point `t`, in cases where
  /// 1.0 > `t` > 0.0.
  @protected
  double transformInternal(double t) {
    throw UnimplementedError();
  }

  /// Returns a new curve that is the reversed inversion of this one.
  ///
  /// This is often useful with [CurvedAnimation.reverseCurve].
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_flipped.mp4}
  ///
  /// See also:
  ///
  ///  * [FlippedCurve], the class that is used to implement this getter.
  ///  * [ReverseAnimation], which reverses an [Animation] rather than a [Curve].
  ///  * [CurvedAnimation], which can take a separate curve and reverse curve.
  Curve get flipped => FlippedCurve(this);

  @override
  String toString() {
    return '$runtimeType';
  }
}

/// The identity map over the unit interval.
///
/// See [Curves.linear] for an instance of this class.
class _Linear extends Curve {
  const _Linear._();

  @override
  double transformInternal(double t) => t;
}

/// A sawtooth curve that repeats a given number of times over the unit interval.
///
/// The curve rises linearly from 0.0 to 1.0 and then falls discontinuously back
/// to 0.0 each iteration.
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_sawtooth.mp4}
class SawTooth extends Curve {
  /// Creates a sawtooth curve.
  ///
  /// The [count] argument must not be null.
  const SawTooth(this.count) : assert(count != null);

  /// The number of repetitions of the sawtooth pattern in the unit interval.
  final int count;

  @override
  double transformInternal(double t) {
    t *= count;
    return t - t.truncateToDouble();
  }

  @override
  String toString() {
    return '$runtimeType($count)';
  }
}

/// A curve that is 0.0 until [begin], then curved (according to [curve]) from
/// 0.0 at [begin] to 1.0 at [end], then remains 1.0 past [end].
///
/// An [Interval] can be used to delay an animation. For example, a six second
/// animation that uses an [Interval] with its [begin] set to 0.5 and its [end]
/// set to 1.0 will essentially become a three-second animation that starts
/// three seconds later.
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_interval.mp4}
class Interval extends Curve {
  /// Creates an interval curve.
  ///
  /// The arguments must not be null.
  const Interval(this.begin, this.end, { this.curve = Curves.linear })
    : assert(begin != null),
      assert(end != null),
      assert(curve != null);

  /// The largest value for which this interval is 0.0.
  ///
  /// From t=0.0 to t=`begin`, the interval's value is 0.0.
  final double begin;

  /// The smallest value for which this interval is 1.0.
  ///
  /// From t=`end` to t=1.0, the interval's value is 1.0.
  final double end;

  /// The curve to apply between [begin] and [end].
  final Curve curve;

  @override
  double transformInternal(double t) {
    assert(begin >= 0.0);
    assert(begin <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
    assert(end >= begin);
    t = ((t - begin) / (end - begin)).clamp(0.0, 1.0) as double;
    if (t == 0.0 || t == 1.0)
      return t;
    return curve.transform(t);
  }

  @override
  String toString() {
    if (curve is! _Linear)
      return '$runtimeType($begin\u22EF$end)\u27A9$curve';
    return '$runtimeType($begin\u22EF$end)';
  }
}

/// A curve that is 0.0 until it hits the threshold, then it jumps to 1.0.
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_threshold.mp4}
class Threshold extends Curve {
  /// Creates a threshold curve.
  ///
  /// The [threshold] argument must not be null.
  const Threshold(this.threshold) : assert(threshold != null);

  /// The value before which the curve is 0.0 and after which the curve is 1.0.
  ///
  /// When t is exactly [threshold], the curve has the value 1.0.
  final double threshold;

  @override
  double transformInternal(double t) {
    assert(threshold >= 0.0);
    assert(threshold <= 1.0);
    return t < threshold ? 0.0 : 1.0;
  }
}

/// A cubic polynomial mapping of the unit interval.
///
/// The [Curves] class contains some commonly used cubic curves:
///
///  * [Curves.ease]
///  * [Curves.easeIn]
///  * [Curves.easeOut]
///  * [Curves.easeInOut]
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out.mp4}
///
/// The [Cubic] class implements third-order Bézier curves.
class Cubic extends Curve {
  /// Creates a cubic curve.
  ///
  /// Rather than creating a new instance, consider using one of the common
  /// cubic curves in [Curves].
  ///
  /// The [a], [b], [c], and [d] arguments must not be null.
  const Cubic(this.a, this.b, this.c, this.d)
    : assert(a != null),
      assert(b != null),
      assert(c != null),
      assert(d != null);

  /// The x coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double a;

  /// The y coordinate of the first control point.
  ///
  /// The line through the point (0, 0) and the first control point is tangent
  /// to the curve at the point (0, 0).
  final double b;

  /// The x coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double c;

  /// The y coordinate of the second control point.
  ///
  /// The line through the point (1, 1) and the second control point is tangent
  /// to the curve at the point (1, 1).
  final double d;

  static const double _cubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    return 3 * a * (1 - m) * (1 - m) * m +
           3 * b * (1 - m) *           m * m +
                                       m * m * m;
  }

  @override
  double transformInternal(double t) {
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final double midpoint = (start + end) / 2;
      final double estimate = _evaluateCubic(a, c, midpoint);
      if ((t - estimate).abs() < _cubicErrorBound)
        return _evaluateCubic(b, d, midpoint);
      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }

  @override
  String toString() {
    return '$runtimeType(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)}, ${c.toStringAsFixed(2)}, ${d.toStringAsFixed(2)})';
  }
}

/// Abstract class that defines an API for evaluating 2D parametric curves.
abstract class Curve2D {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Curve2D();

  /// Returns the position of the curve at point `t`.
  ///
  /// This function must ensure that the value of `t` is between 0.0 and
  /// 1.0, inclusive.
  ///
  /// It is recommended that subclasses override [transformInternal] instead of
  /// this function, as the above case is already enforced in the default
  /// implementation of [transform], which delegates the remaining logic to
  /// [transformInternal].
  Offset transform(double t) {
    assert(t >= 0.0 && t <= 1.0, 'parameter t is ${t.toStringAsFixed(2)}, which is outside of the range [0.0, 1.0]');
    return transformInternal(t);
  }

  /// Returns the position of the curve at point `t`, where `t` is between 0.0
  /// and 1.0, inclusive.
  @protected
  Offset transformInternal(double t) {
    throw UnimplementedError();
  }

  @override
  String toString() => '$runtimeType';
}

class Curve2DSample {
  const Curve2DSample(this.t, this.value);
  final double t;
  final Offset value;
}

/// A spline that passes smoothly through the given control points using a
/// centripetal Catmull-Rom spline.
///
/// When the curve is evaluated with [transform], the output values will move
/// smoothly from one control point to the next, passing through the control
/// points.
///
/// Unlike Bezier splines, Catmull-Rom splines have the advantage that their
/// curves pass through the control points given to them. They are both cubic
/// polynomial representations, and, in fact, Catmull-Rom splines can be
/// converted mathematically into Bezier splines. This class implements a
/// "centripetal" Catmull-Rom spline implementation. The term centripetal
/// implies that it won't form loops or self-intersections within a single
/// segment.
///
/// See also:
///
///  * A Wikipedia article on [centripetal Catmull-Rom splines](https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline).
///  * This [paper on using Catmull-Rom splines](http://faculty.cs.tamu.edu/schaefer/research/cr_cad.pdf).
class CatmullRomSpline extends Curve2D {
  /// Constructs a centripetal Catmull-Rom spline curve.
  ///
  /// The `points` argument is a list of four or more points that describe the
  /// points that the curve must pass through.
  ///
  /// The optional `tension` argument controls how tightly the curve approaches
  /// the given `points`. It must be in the range 0.0 to 1.0, inclusive. It
  /// defaults to 0.0, which provides the smoothest curve. A value of 1.0
  /// produces a linear interpolation between points.
  ///
  /// The optional `endHandle` and `startHandle` points are the beginning and
  /// ending handle positions. If not specified, they are created automatically
  /// by extending the line formed by the first and/or last line segment in the
  /// input points, respectively.
  ///
  /// The `tension` and `points` arguments must not be null, and the `points`
  /// list must contain at least four points to interpolate.
  CatmullRomSpline(
      List<Offset> points, {
        double tension = 0.0,
        Offset startHandle,
        Offset endHandle,
      })  : assert(points != null),
        assert(tension != null),
        assert(tension <= 1.0, 'tension $tension must not be greater than 1.0.'),
        assert(tension >= 0.0, 'tension $tension must not be negative.'),
        assert(points.length > 3, 'There must be at least four points to create a CatmullRom curve.') {
    // If not specified, select the first and last control points (which are
    // handles: they are not intersected by the resulting curve) so that they
    // extend the first and last segments, respectively.
    startHandle ??= points[0] * 2.0 - points[1];
    endHandle ??= points.last * 2.0 - points[points.length - 2];
    final List<Offset> allPoints = <Offset>[
      startHandle,
      ...points,
      endHandle,
    ];

    // An alpha of 0.5 is what makes it a centripetal Catmull-Rom spline. A
    // value of 0.0 would make it a uniform Catmull-Rom spline, and a value of
    // 1.0 would make it a chordal Catmull-Rom spline. Non-centripetal values
    // for alpha can give self-intersecting behavior or looping within a
    // segment.
    const double alpha = 0.5;
    for (int i = 0; i < allPoints.length - 3; ++i) {
      final List<Offset> curve = <Offset>[allPoints[i], allPoints[i + 1], allPoints[i + 2], allPoints[i + 3]];
      final Offset diffCurve10 = curve[1] - curve[0];
      final Offset diffCurve21 = curve[2] - curve[1];
      final Offset diffCurve32 = curve[3] - curve[2];
      final double t01 = math.pow(diffCurve10.distance, alpha).toDouble();
      final double t12 = math.pow(diffCurve21.distance, alpha).toDouble();
      final double t23 = math.pow(diffCurve32.distance, alpha).toDouble();
      final double reverseTension = 1.0 - tension;

      final Offset m1 = (diffCurve21 + (diffCurve10 / t01 - (curve[2] - curve[0]) / (t01 + t12)) * t12) * reverseTension;
      final Offset m2 = (diffCurve21 + (diffCurve32 / t23 - (curve[3] - curve[1]) / (t12 + t23)) * t12) * reverseTension;
      final Offset sumM12 = m1 + m2;

      final List<Offset> controls = <Offset>[
        diffCurve21 * -2.0 + sumM12,
        diffCurve21 * 3.0 - m1 - sumM12,
        m1,
        curve[1],
      ];
      _controlPoints.add(controls);
    }
  }

  final List<List<Offset>> _controlPoints = <List<Offset>>[];

  @override
  Offset transformInternal(double t) {
    assert(t >= 0.0 && t <= 1.0, 'parametric value $t is outside of [0, 1] range.');
    final double length = _controlPoints.length.toDouble();
    double position;
    double localT;
    int index;
    if (t < 1.0) {
      position = t * length;
      localT = position % 1.0;
      index = position.floor();
    } else {
      position = length;
      localT = 1.0;
      index = _controlPoints.length - 1;
    }
    final List<Offset> controlPoints = _controlPoints[index];
    final double localT2 = localT * localT;
    return controlPoints[0] * localT2 * localT
         + controlPoints[1] * localT2
         + controlPoints[2] * localT
         + controlPoints[3];
  }

  /// Generates a list of samples with a recursive subdivision until a tolerance
  /// of `tolerance` is reached.
  List<Curve2DSample> generateSamples({double tolerance = 1e-10, double start = 0.0, double end = 1.0}) {
    assert(tolerance != null);
    assert(start != null);
    assert(end != null);
    assert(end > start);
    final Curve2DSample first = Curve2DSample(start, transform(start));
    final List<Curve2DSample> samples = <Curve2DSample>[first];
    final math.Random rand = math.Random((_controlPoints[0][1].dx * 1000).round());
    bool flat(Offset p, Offset q, Offset r) {
      final Offset pr = p - r;
      final Offset qr = q - r;
      final double z = pr.dx * qr.dy - qr.dx * pr.dy;
      return (z * z) < tolerance;
    }

    void sample(Curve2DSample p, Curve2DSample q) {
      // Pick a random point somewhat near the center.
      double t = p.t + (0.45 + 0.1 * rand.nextDouble()) * (q.t - p.t);
      final Curve2DSample r = Curve2DSample(t, transform(t));

      if (flat(p.value, q.value, r.value)) {
        samples.add(q);
      } else {
        sample(p, r);
        sample(r, q);
      }
    }
    final Curve2DSample last = Curve2DSample(end, transform(end));
    sample(first, last);
    return samples;
  }

  /// Finds the time that corresponds to the x value of the spline at parametric
  /// value t.
  ///
  /// Note that this will only work properly for curves which are single-valued
  /// in X. For curves that are not single-valued, it will return only one of
  /// the values.
  double findInverse(double t) {
    assert(t != null);
    double start = 0.0;
    double end = 1.0;
    double mid;
    double offsetToOrigin(double pos) => t - transform(pos).dx;
    // Use a binary search to find the inverse point within 1e-6, or 100
    // subdivisions, whichever comes first.
    const double errorLimit = 1e-6;
    int count = 100;
    final double startValue = offsetToOrigin(start);
    while ((end - start) / 2.0 > errorLimit && count > 0) {
      mid = (end + start) / 2.0;
      final double value = offsetToOrigin(mid);
      if (value.sign == startValue.sign) {
        start = mid;
      } else {
        end = mid;
      }
      count--;
    }
    return mid;
  }
}

/// A curve that passes smoothly through the given control points using a
/// centripetal Catmull-Rom spline.
///
/// When the curve is evaluated with [transform], the values will interpolate
/// smoothly from one control point to the next, passing through (0.0, 0.0), the
/// given points, and (1.0, 1.0).
///
/// Unlike [Bezier] curves, Catmull-Rom curves have the advantage that their
/// curves pass through the control points given to them. They are both cubic
/// polynomial representations, and, in fact, Catmull-Rom splines can be
/// converted mathematically into Bezier splines. This class implements a
/// centripetal Catmull-Rom curve. The term centripetal implies that it won't
/// form loops or self-intersections within a single segment, and corresponds to
/// a Catmull-Rom α (alpha) value of 0.5.
///
/// See also:
///
///  * A Wikipedia article on [centripetal Catmull-Rom splines](https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline).
///  * [new CatmullRomCurve] for a description of the constraints put on the
///    input control points.
///  * This [paper on using Catmull-Rom splines](http://faculty.cs.tamu.edu/schaefer/research/cr_cad.pdf).
class CatmullRomCurve extends Curve {
  /// Constructs a centripetal [CatmullRomCurve].
  ///
  /// It takes a list of two or more points that describe the points that the
  /// curve must pass through.
  ///
  /// The `points` list must meet the following criteria:
  ///
  ///  * The `points` and `tension` arguments must not be null.
  ///  * The list of `points` must contain at least two points.
  ///  * The X value of each point must be greater than 0.0 and less then 1.0.
  ///  * The X values of each point must be greater than the
  ///    previous point's X value (i.e. monotonically increasing).
  ///  * The angle between two adjacent segments must not be less than 60
  ///    degrees. As the `tension` increases, this value decreases, and angles of
  ///    zero degrees are accepted at a tension of 1.0.
  ///  * The (non-axis-aligned) non-adjacent bounding rectangles, parallel to
  ///    the control segments of the curve must not overlap.
  ///
  /// The static function [validateControlPoints] can be used to check that
  /// these conditions are met, and will return true if they are. In debug mode,
  /// it will also optionally return a list of reasons in text form. In debug
  /// mode, this constructor will assert that these conditions are met and print
  /// the reasons.
  ///
  /// When the curve is evaluated with [transform], the values will interpolate
  /// smoothly from one control point to the next, passing through (0.0, 0.0), the
  /// given points, and (1.0, 1.0).
  ///
  /// The optional `tension` argument controls how tightly the curve approaches
  /// the given `points`. It must be in the range 0.0 to 1.0, inclusive. It
  /// defaults to 0.0, which provides the smoothest curve. A value of 1.0
  /// is equivalent to a linear interpolation between points.
  ///
  /// See also:
  ///
  ///  * This [paper on using Catmull-Rom splines](http://faculty.cs.tamu.edu/schaefer/research/cr_cad.pdf).
  CatmullRomCurve(this.controlPoints, {this.tension = 0.0})
      : assert(tension != null),
        assert(() {
          final List<String> reasons = <String>[];
          final bool valid = validateControlPoints(
            controlPoints,
            tension: tension,
            reasons: reasons,
          );
          if (!valid) {
            debugPrint('Validation of $runtimeType failed:');
            for (String reason in reasons) {
              debugPrint('  $reason');
            }
          }
          return valid;
        }(), 'control points $controlPoints could not be validated.') {
    _valueSpline = CatmullRomSpline(controlPoints, tension: tension);
    _precomputedSamples = _valueSpline.generateSamples(start: 0.0, end: 1.0);
  }

  /// The 2D spline created for this curve.
  CatmullRomSpline get valueSpline => _valueSpline;
  CatmullRomSpline _valueSpline;

  /// The control points used to create this curve.
  final List<Offset> controlPoints;

  /// The "tension" of the curve.
  ///
  /// The optional `tension` argument controls how tightly the curve approaches
  /// the given `points`. It must be in the range 0.0 to 1.0, inclusive. It
  /// defaults to 0.0, which provides the smoothest curve. A value of 1.0
  /// is equivalent to a linear interpolation between points.
  final double tension;

  /// Validates that a given set of control points for a [CatmullRomCurve] is
  /// well-formed and will not produce a spline that self-intersects.
  ///
  /// This is used in debug mode to validate a curve to make sure that it won't
  /// violate the contract for a [Curve], in that it be non-self-intersecting
  /// and single-valued.
  ///
  /// It uses the methodology laid out in [this paper](http://faculty.cs.tamu.edu/schaefer/research/cr_cad.pdf).
  ///
  /// First, it calculates the maximum extent bounding boxes of the values that
  /// the curve can take on, and makes sure that non-adjacent control point
  /// segments do not have overlapping bounding boxes. Then, for the adjacent
  /// segments, ensures that they have an angle between them of greater than 60
  /// degrees. These conditions together ensure that the curve won't be
  /// self-intersecting.
  ///
  /// In debug mode, and `reasons` is non-null, this function will fill in
  /// `reasons` with descriptions of the problems encountered.
  static bool validateControlPoints(
      List<Offset> controlPoints, {
      double tension = 0.0,
      List<String> reasons,
    }) {
    assert(tension != null);
    if (controlPoints == null) {
      assert(() {
        reasons?.add('Supplied control points cannot be null');
        return true;
      }());
      return false;
    }

    if (controlPoints.length < 4) {
      assert(() {
        reasons?.add('There must be at least four points supplied to create a valid curve.');
        return true;
      }());
      return false;
    }

    if (controlPoints[0] != Offset.zero) {
      assert(() {
        reasons?.add('The first control point must be Offset(0.0, 0.0), not ${controlPoints[0]}.');
        return true;
      }());
      return false;
    }

    if (controlPoints.last != const Offset(1.0, 1.0)) {
      assert(() {
        reasons?.add('The last control point must be Offset(1.0, 1.0), not ${controlPoints[0]}.');
        return true;
      }());
      return false;
    }

    final Offset startHandle = controlPoints[0] * 2.0 - controlPoints[1];
    final Offset endHandle = controlPoints.last * 2.0 - controlPoints[controlPoints.length - 2];
    controlPoints = <Offset>[startHandle, ...controlPoints, endHandle];
    double lastX = -double.infinity;
    for (int i = 0; i < controlPoints.length; ++i) {
      if (i > 1 && i < controlPoints.length - 2 && (controlPoints[i].dx <= 0.0 || controlPoints[i].dx >= 1.0)) {
        assert(() {
          reasons?.add('Points must have X values between 0.0 and 1.0, exclusive. '
              'Point $i has an x value (${controlPoints[i].dx}) which is outside the range.');
          return true;
        }());
        return false;
      }
      if (controlPoints[i].dx <= lastX) {
        assert(() {
          reasons?.add('Each X coordinate must be greater than the preceding X coordinate '
              '(i.e. must be monotonically increasing in X). Point $i has x value of ${controlPoints[i].dx}, '
              'which is not greater than $lastX');
          return true;
        }());
        return false;
      }
      lastX = controlPoints[i].dx;
    }

    bool success = true;

    // An empirical test to make sure things are single-valued in X.
    lastX = -double.infinity;
    final CatmullRomSpline testSpline = CatmullRomSpline(controlPoints, tension: tension);
    final double start = testSpline.findInverse(0.0);
    final double end = testSpline.findInverse(1.0);
    final List<Curve2DSample> adaptivePoints = testSpline.generateSamples(start: start, end: end);
    for (int i = 0; i < adaptivePoints.length; i++) {
      final Curve2DSample sample = adaptivePoints[i];
      final Offset point = sample.value;
      final double t = sample.t;
      final double x = point.dx;
      if (t >= start && t <= end && (x < -1e-3 || x > 1.0 + 1e-3)) {
        bool bail = true;
        assert(() {
          reasons?.add('The resulting curve has an X value ($x) which is outside of the range [0.0, 1.0], inclusive.');
          // No need to keep going if we're not giving reasons.
          bail = reasons == null;
          success = false;
          return true;
        }());
        if (bail) {
          // If we're not in debug mode, then we want to bail immediately
          // instead of checking all the segments.
          return false;
        }
      }
      if (x < lastX) {
        bool bail = true;
        assert(() {
          reasons?.add('The curve has more than one Y value at x = $x. Try moving '
            'some control points further apart in X, or increasing the tension.');
          // No need to keep going if we're not giving reasons.
          bail = reasons == null;
          success = false;
          return true;
        }());
        if (bail) {
          // If we're not in debug mode, then we want to bail immediately
          // instead of checking all the segments.
          return false;
        }
      }
      lastX = x;
    }
    return success;
  }

  List<Curve2DSample> _precomputedSamples;

  @override
  double transformInternal(double t) {
    assert(t != null);
    int start = 0;
    int end = _precomputedSamples.length - 1;
    int mid;
    Offset value;
    Offset startValue = _precomputedSamples[start].value;
    Offset endValue = _precomputedSamples[end].value;
    // Use a binary search to find the index of the sample point that is just
    // before t.
    while (end - start > 1) {
      mid = (end + start) ~/ 2;
      value = _precomputedSamples[mid].value;
      if (t >= value.dx) {
        start = mid;
        startValue = value;
      } else {
        end = mid;
        endValue = value;
      }
    }

    // Now interpolate between the found sample and the next one.
    final double t2 = (t - startValue.dx) / (endValue.dx - startValue.dx);
    return lerpDouble(startValue.dy, endValue.dy, t2);
  }
}

/// A curve that is the reversed inversion of its given curve.
///
/// This curve evaluates the given curve in reverse (i.e., from 1.0 to 0.0 as t
/// increases from 0.0 to 1.0) and returns the inverse of the given curve's
/// value (i.e., 1.0 minus the given curve's value).
///
/// This is the class used to implement the [flipped] getter on curves.
///
/// This is often useful with [CurvedAnimation.reverseCurve].
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_flipped.mp4}
///
/// See also:
///
///  * [Curve.flipped], which provides the [FlippedCurve] of a [Curve].
///  * [ReverseAnimation], which reverses an [Animation] rather than a [Curve].
///  * [CurvedAnimation], which can take a separate curve and reverse curve.
class FlippedCurve extends Curve {
  /// Creates a flipped curve.
  ///
  /// The [curve] argument must not be null.
  const FlippedCurve(this.curve) : assert(curve != null);

  /// The curve that is being flipped.
  final Curve curve;

  @override
  double transformInternal(double t) => 1.0 - curve.transform(1.0 - t);

  @override
  String toString() {
    return '$runtimeType($curve)';
  }
}

/// A curve where the rate of change starts out quickly and then decelerates; an
/// upside-down `f(t) = t²` parabola.
///
/// This is equivalent to the Android `DecelerateInterpolator` class with a unit
/// factor (the default factor).
///
/// See [Curves.decelerate] for an instance of this class.
class _DecelerateCurve extends Curve {
  const _DecelerateCurve._();

  @override
  double transformInternal(double t) {
    // Intended to match the behavior of:
    // https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/view/animation/DecelerateInterpolator.java
    // ...as of December 2016.
    t = 1.0 - t;
    return 1.0 - t * t;
  }
}

// BOUNCE CURVES

double _bounce(double t) {
  if (t < 1.0 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + 0.75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + 0.9375;
  }
  t -= 2.625 / 2.75;
  return 7.5625 * t * t + 0.984375;
}

/// An oscillating curve that grows in magnitude.
///
/// See [Curves.bounceIn] for an instance of this class.
class _BounceInCurve extends Curve {
  const _BounceInCurve._();

  @override
  double transformInternal(double t) {
    return 1.0 - _bounce(1.0 - t);
  }
}

/// An oscillating curve that shrink in magnitude.
///
/// See [Curves.bounceOut] for an instance of this class.
class _BounceOutCurve extends Curve {
  const _BounceOutCurve._();

  @override
  double transformInternal(double t) {
    return _bounce(t);
  }
}

/// An oscillating curve that first grows and then shrink in magnitude.
///
/// See [Curves.bounceInOut] for an instance of this class.
class _BounceInOutCurve extends Curve {
  const _BounceInOutCurve._();

  @override
  double transformInternal(double t) {
    if (t < 0.5)
      return (1.0 - _bounce(1.0 - t * 2.0)) * 0.5;
    else
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
  }
}


// ELASTIC CURVES

/// An oscillating curve that grows in magnitude while overshooting its bounds.
///
/// An instance of this class using the default period of 0.4 is available as
/// [Curves.elasticIn].
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in.mp4}
class ElasticInCurve extends Curve {
  /// Creates an elastic-in curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticIn].
  const ElasticInCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period) as double;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

/// An oscillating curve that shrinks in magnitude while overshooting its bounds.
///
/// An instance of this class using the default period of 0.4 is available as
/// [Curves.elasticOut].
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_out.mp4}
class ElasticOutCurve extends Curve {
  /// Creates an elastic-out curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticOut].
  const ElasticOutCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    return math.pow(2.0, -10 * t) * math.sin((t - s) * (math.pi * 2.0) / period) + 1.0 as double;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

/// An oscillating curve that grows and then shrinks in magnitude while
/// overshooting its bounds.
///
/// An instance of this class using the default period of 0.4 is available as
/// [Curves.elasticInOut].
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in_out.mp4}
class ElasticInOutCurve extends Curve {
  /// Creates an elastic-in-out curve.
  ///
  /// Rather than creating a new instance, consider using [Curves.elasticInOut].
  const ElasticInOutCurve([this.period = 0.4]);

  /// The duration of the oscillation.
  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0)
      return -0.5 * math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period);
    else
      return math.pow(2.0, -10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period) * 0.5 + 1.0 as double;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}


// PREDEFINED CURVES

/// A collection of common animation curves.
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_decelerate.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_sine.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quad.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_cubic.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quart.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quint.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_expo.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_circ.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_back.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_sine.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quad.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_cubic.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quart.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quint.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_expo.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_circ.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_back.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_sine.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quad.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_cubic.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quart.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quint.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_expo.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_circ.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_back.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_out.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_fast_out_slow_in.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_slow_middle.mp4}
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_linear.mp4}
///
/// See also:
///
///  * [Curve], the interface implemented by the constants available from the
///    [Curves] class.
class Curves {
  // This class is not meant to be instatiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  Curves._();

  /// A linear animation curve.
  ///
  /// This is the identity map over the unit interval: its [Curve.transform]
  /// method returns its input unmodified. This is useful as a default curve for
  /// cases where a [Curve] is required but no actual curve is desired.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_linear.mp4}
  static const Curve linear = _Linear._();

  /// A curve where the rate of change starts out quickly and then decelerates; an
  /// upside-down `f(t) = t²` parabola.
  ///
  /// This is equivalent to the Android `DecelerateInterpolator` class with a unit
  /// factor (the default factor).
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_decelerate.mp4}
  static const Curve decelerate = _DecelerateCurve._();

  /// A curve that is very steep and linear at the beginning, but quickly flattens out
  /// and very slowly eases in.
  ///
  /// By default is the curve used to animate pages on iOS back to their original
  /// position if a swipe gesture is ended midway through a swipe.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/fast_linear_to_slow_ease_in.mp4}
  static const Cubic fastLinearToSlowEaseIn = Cubic(0.18, 1.0, 0.04, 1.0);

  /// A cubic animation curve that speeds up quickly and ends slowly.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease.mp4}
  static const Cubic ease = Cubic(0.25, 0.1, 0.25, 1.0);

  /// A cubic animation curve that starts slowly and ends quickly.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in.mp4}
  static const Cubic easeIn = Cubic(0.42, 0.0, 1.0, 1.0);

  /// A cubic animation curve that starts starts slowly and ends linearly.
  ///
  /// The symmetric animation to [linearToEaseOut].
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_to_linear.mp4}
  static const Cubic easeInToLinear = Cubic(0.67, 0.03, 0.65, 0.09);

  /// A cubic animation curve that starts slowly and ends quickly. This is
  /// similar to [Curves.easeIn], but with sinusoidal easing for a slightly less
  /// abrupt beginning and end. Nonetheless, the result is quite gentle and is
  /// hard to distinguish from [Curves.linear] at a glance.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_sine.mp4}
  static const Cubic easeInSine = Cubic(0.47, 0.0, 0.745, 0.715);

  /// A cubic animation curve that starts slowly and ends quickly. Based on a
  /// quadratic equation where `f(t) = t²`, this is effectively the inverse of
  /// [Curves.decelerate].
  ///
  /// Compared to [Curves.easeInSine], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quad.mp4}
  static const Cubic easeInQuad = Cubic(0.55, 0.085, 0.68, 0.53);

  /// A cubic animation curve that starts slowly and ends quickly. This curve is
  /// based on a cubic equation where `f(t) = t³`. The result is a safe sweet
  /// spot when choosing a curve for widgets animating off the viewport.
  ///
  /// Compared to [Curves.easeInQuad], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_cubic.mp4}
  static const Cubic easeInCubic = Cubic(0.55, 0.055, 0.675, 0.19);

  /// A cubic animation curve that starts slowly and ends quickly. This curve is
  /// based on a quartic equation where `f(t) = t⁴`.
  ///
  /// Animations using this curve or steeper curves will benefit from a longer
  /// duration to avoid motion feeling unnatural.
  ///
  /// Compared to [Curves.easeInCubic], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quart.mp4}
  static const Cubic easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22);

  /// A cubic animation curve that starts slowly and ends quickly. This curve is
  /// based on a quintic equation where `f(t) = t⁵`.
  ///
  /// Compared to [Curves.easeInQuart], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quint.mp4}
  static const Cubic easeInQuint = Cubic(0.755, 0.05, 0.855, 0.06);

  /// A cubic animation curve that starts slowly and ends quickly. This curve is
  /// based on an exponential equation where `f(t) = 2¹⁰⁽ᵗ⁻¹⁾`.
  ///
  /// Using this curve can give your animations extra flare, but a longer
  /// duration may need to be used to compensate for the steepness of the curve.
  ///
  /// Compared to [Curves.easeInQuint], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_expo.mp4}
  static const Cubic easeInExpo = Cubic(0.95, 0.05, 0.795, 0.035);

  /// A cubic animation curve that starts slowly and ends quickly. This curve is
  /// effectively the bottom-right quarter of a circle.
  ///
  /// Like [Curves.easeInExpo], this curve is fairly dramatic and will reduce
  /// the clarity of an animation if not given a longer duration.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_circ.mp4}
  static const Cubic easeInCirc = Cubic(0.6, 0.04, 0.98, 0.335);

  /// A cubic animation curve that starts slowly and ends quickly. This curve
  /// is similar to [Curves.elasticIn] in that it overshoots its bounds before
  /// reaching its end. Instead of repeated swinging motions before ascending,
  /// though, this curve overshoots once, then continues to ascend.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_back.mp4}
  static const Cubic easeInBack = Cubic(0.6, -0.28, 0.735, 0.045);

  /// A cubic animation curve that starts quickly and ends slowly.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out.mp4}
  static const Cubic easeOut = Cubic(0.0, 0.0, 0.58, 1.0);

  /// A cubic animation curve that starts linearly and ends slowly.
  ///
  /// A symmetric animation to [easeInToLinear].
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/linear_to_ease_out.mp4}
  static const Cubic linearToEaseOut = Cubic(0.35, 0.91, 0.33, 0.97);

  /// A cubic animation curve that starts quickly and ends slowly. This is
  /// similar to [Curves.easeOut], but with sinusoidal easing for a slightly
  /// less abrupt beginning and end. Nonetheless, the result is quite gentle and
  /// is hard to distinguish from [Curves.linear] at a glance.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_sine.mp4}
  static const Cubic easeOutSine = Cubic(0.39, 0.575, 0.565, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This is
  /// effectively the same as [Curves.decelerate], only simulated using a cubic
  /// bezier function.
  ///
  /// Compared to [Curves.easeOutSine], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quad.mp4}
  static const Cubic easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// a flipped version of [Curves.easeInCubic].
  ///
  /// The result is a safe sweet spot when choosing a curve for animating a
  /// widget's position entering or already inside the viewport.
  ///
  /// Compared to [Curves.easeOutQuad], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_cubic.mp4}
  static const Cubic easeOutCubic = Cubic(0.215, 0.61, 0.355, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// a flipped version of [Curves.easeInQuart].
  ///
  /// Animations using this curve or steeper curves will benefit from a longer
  /// duration to avoid motion feeling unnatural.
  ///
  /// Compared to [Curves.easeOutCubic], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quart.mp4}
  static const Cubic easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// a flipped version of [Curves.easeInQuint].
  ///
  /// Compared to [Curves.easeOutQuart], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quint.mp4}
  static const Cubic easeOutQuint = Cubic(0.23, 1.0, 0.32, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// a flipped version of [Curves.easeInExpo]. Using this curve can give your
  /// animations extra flare, but a longer duration may need to be used to
  /// compensate for the steepness of the curve.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_expo.mp4}
  static const Cubic easeOutExpo = Cubic(0.19, 1.0, 0.22, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// effectively the top-left quarter of a circle.
  ///
  /// Like [Curves.easeOutExpo], this curve is fairly dramatic and will reduce
  /// the clarity of an animation if not given a longer duration.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_circ.mp4}
  static const Cubic easeOutCirc = Cubic(0.075, 0.82, 0.165, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly. This curve is
  /// similar to [Curves.elasticOut] in that it overshoots its bounds before
  /// reaching its end. Instead of repeated swinging motions after ascending,
  /// though, this curve only overshoots once.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_back.mp4}
  static const Cubic easeOutBack = Cubic(0.175, 0.885, 0.32, 1.275);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out.mp4}
  static const Cubic easeInOut = Cubic(0.42, 0.0, 0.58, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This is similar to [Curves.easeInOut], but with sinusoidal easing
  /// for a slightly less abrupt beginning and end.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_sine.mp4}
  static const Cubic easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInQuad] as the first
  /// half, and [Curves.easeOutQuad] as the second.
  ///
  /// Compared to [Curves.easeInOutSine], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quad.mp4}
  static const Cubic easeInOutQuad = Cubic(0.455, 0.03, 0.515, 0.955);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInCubic] as the first
  /// half, and [Curves.easeOutCubic] as the second.
  ///
  /// The result is a safe sweet spot when choosing a curve for a widget whose
  /// initial and final positions are both within the viewport.
  ///
  /// Compared to [Curves.easeInOutQuad], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_cubic.mp4}
  static const Cubic easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInQuart] as the first
  /// half, and [Curves.easeOutQuart] as the second.
  ///
  /// Animations using this curve or steeper curves will benefit from a longer
  /// duration to avoid motion feeling unnatural.
  ///
  /// Compared to [Curves.easeInOutCubic], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quart.mp4}
  static const Cubic easeInOutQuart = Cubic(0.77, 0.0, 0.175, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInQuint] as the first
  /// half, and [Curves.easeOutQuint] as the second.
  ///
  /// Compared to [Curves.easeInOutQuart], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quint.mp4}
  static const Cubic easeInOutQuint = Cubic(0.86, 0.0, 0.07, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly.
  ///
  /// Since this curve is arrived at with an exponential function, the midpoint
  /// is exceptionally steep. Extra consideration should be taken when designing
  /// an animation using this.
  ///
  /// Compared to [Curves.easeInOutQuint], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_expo.mp4}
  static const Cubic easeInOutExpo = Cubic(1.0, 0.0, 0.0, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInCirc] as the first
  /// half, and [Curves.easeOutCirc] as the second.
  ///
  /// Like [Curves.easeInOutExpo], this curve is fairly dramatic and will reduce
  /// the clarity of an animation if not given a longer duration.
  ///
  /// Compared to [Curves.easeInOutExpo], this curve is slightly steeper.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_circ.mp4}
  static const Cubic easeInOutCirc = Cubic(0.785, 0.135, 0.15, 0.86);

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly. This curve can be imagined as [Curves.easeInBack] as the first
  /// half, and [Curves.easeOutBack] as the second.
  ///
  /// Since two curves are used as a basis for this curve, the resulting
  /// animation will overshoot its bounds twice before reaching its end - first
  /// by exceeding its lower bound, then exceeding its upper bound and finally
  /// descending to its final position.
  ///
  /// Derived from Robert Penner’s easing functions.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_back.mp4}
  static const Cubic easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);

  /// A curve that starts quickly and eases into its final position.
  ///
  /// Over the course of the animation, the object spends more time near its
  /// final destination. As a result, the user isn’t left waiting for the
  /// animation to finish, and the negative effects of motion are minimized.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_fast_out_slow_in.mp4}
  static const Cubic fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);

  /// A cubic animation curve that starts quickly, slows down, and then ends
  /// quickly.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_slow_middle.mp4}
  static const Cubic slowMiddle = Cubic(0.15, 0.85, 0.85, 0.15);

  /// An oscillating curve that grows in magnitude.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
  static const Curve bounceIn = _BounceInCurve._();

  /// An oscillating curve that first grows and then shrink in magnitude.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_out.mp4}
  static const Curve bounceOut = _BounceOutCurve._();

  /// An oscillating curve that first grows and then shrink in magnitude.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in_out.mp4}
  static const Curve bounceInOut = _BounceInOutCurve._();

  /// An oscillating curve that grows in magnitude while overshooting its bounds.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in.mp4}
  static const ElasticInCurve elasticIn = ElasticInCurve();

  /// An oscillating curve that shrinks in magnitude while overshooting its bounds.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_out.mp4}
  static const ElasticOutCurve elasticOut = ElasticOutCurve();

  /// An oscillating curve that grows and then shrinks in magnitude while overshooting its bounds.
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in_out.mp4}
  static const ElasticInOutCurve elasticInOut = ElasticInOutCurve();
}
