// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

double _evaluateCubic(double a, double b, double m) {
  return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
}

const double _kCubicErrorBound = 0.001;

/// A mapping of the unit interval to the unit interval
///
/// A curve must map 0.0 to 0.0 and 1.0 to 1.0.
abstract class Curve {
  /// Returns the value of the curve at point [t].
  ///
  /// The value of [t] must be between 0.0 and 1.0, inclusive.
  double transform(double t);
}

/// The identity map over the unit interval.
class Linear implements Curve {
  const Linear();
  double transform(double t) => t;
}

/// A curve that is 0.0 until start, then curved from 0.0 to 1.0 at end, then 1.0.
class Interval implements Curve {
  const Interval(this.start, this.end, { this.curve: Curves.linear });

  /// The smallest value for which this interval is 0.0.
  final double start;

  /// The smallest value for which this interval is 1.0.
  final double end;

  /// The curve to apply between [start] and [end].
  final Curve curve;

  double transform(double t) {
    assert(start >= 0.0);
    assert(start <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
    assert(end >= start);
    t = ((t - start) / (end - start)).clamp(0.0, 1.0);
    if (t == 0.0 || t == 1.0)
      return t;
    return curve.transform(t);
  }
}

/// A cubic polynomial mapping of the unit interval.
class Cubic implements Curve {
  const Cubic(this.a, this.b, this.c, this.d);

  final double a;
  final double b;
  final double c;
  final double d;

  double transform(double t) {
    double start = 0.0;
    double end = 1.0;
    while (true) {
      double midpoint = (start + end) / 2;
      double estimate = _evaluateCubic(a, c, midpoint);
      if ((t - estimate).abs() < _kCubicErrorBound)
        return _evaluateCubic(b, d, midpoint);
      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }
}

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
class BounceInCurve implements Curve {
  const BounceInCurve();
  double transform(double t) {
    return 1.0 - _bounce(1.0 - t);
  }
}

/// An oscillating curve that shrink in magnitude.
class BounceOutCurve implements Curve {
  const BounceOutCurve();
  double transform(double t) {
    return _bounce(t);
  }
}

/// An oscillating curve that first grows and then shrink in magnitude.
class BounceInOutCurve implements Curve {
  const BounceInOutCurve();
  double transform(double t) {
    if (t < 0.5)
      return (1.0 - _bounce(1.0 - t)) * 0.5;
    else
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
  }
}

/// An oscillating curve that grows in magnitude while overshooting its bounds.
class ElasticInCurve implements Curve {
  const ElasticInCurve([this.period = 0.4]);
  final double period;
  double transform(double t) {
    double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
  }
}

/// An oscillating curve that shrinks in magnitude while overshooting its bounds.
class ElasticOutCurve implements Curve {
  const ElasticOutCurve([this.period = 0.4]);
  final double period;
  double transform(double t) {
    double s = period / 4.0;
    return math.pow(2.0, -10 * t) * math.sin((t - s) * (math.PI * 2.0) / period) + 1.0;
  }
}

/// An oscillating curve that grows and then shrinks in magnitude while overshooting its bounds.
class ElasticInOutCurve implements Curve {
  const ElasticInOutCurve([this.period = 0.4]);
  final double period;
  double transform(double t) {
    double s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0)
      return -0.5 * math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
    else
      return math.pow(2.0, -10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period) * 0.5 + 1.0;
  }
}

/// A collection of common animation curves.
class Curves {
  Curves._();

  /// A linear animation curve
  static const Linear linear = const Linear();

  /// A cubic animation curve that speeds up quickly and ends slowly.
  static const Cubic ease = const Cubic(0.25, 0.1, 0.25, 1.0);

  /// A cubic animation curve that starts slowly and ends quickly.
  static const Cubic easeIn = const Cubic(0.42, 0.0, 1.0, 1.0);

  /// A cubic animation curve that starts quickly and ends slowly.
  static const Cubic easeOut = const Cubic(0.0, 0.0, 0.58, 1.0);

  /// A cubic animation curve that starts slowly, speeds up, and then and ends slowly.
  static const Cubic easeInOut = const Cubic(0.42, 0.0, 0.58, 1.0);

  /// An oscillating curve that grows in magnitude.
  static const BounceInCurve bounceIn = const BounceInCurve();

  /// An oscillating curve that first grows and then shrink in magnitude.
  static const BounceOutCurve bounceOut = const BounceOutCurve();

  /// An oscillating curve that first grows and then shrink in magnitude.
  static const BounceInOutCurve bounceInOut = const BounceInOutCurve();

  /// An oscillating curve that grows in magnitude while overshootings its bounds.
  static const ElasticInCurve elasticIn = const ElasticInCurve();

  /// An oscillating curve that shrinks in magnitude while overshootings its bounds.
  static const ElasticOutCurve elasticOut = const ElasticOutCurve();

  /// An oscillating curve that grows and then shrinks in magnitude while overshootings its bounds.
  static const ElasticInOutCurve elasticInOut = const ElasticInOutCurve();

  /// A curve that starts quickly and eases into its final position.
  ///
  /// Over the course of the animation, the object spends more time near its
  /// final destination. As a result, the user isn’t left waiting for the
  /// animation to finish, and the negative effects of motion are minimized.
  static const Curve fastOutSlowIn = const Cubic(0.4, 0.0, 0.2, 1.0);
}
