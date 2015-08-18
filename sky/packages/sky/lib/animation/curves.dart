// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

double _evaluateCubic(double a, double b, double m) {
  // TODO(abarth): Would Math.pow be faster?
  return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
}

const double _kCubicErrorBound = 0.001;

abstract class Curve {
  double transform(double t);
}

class Linear implements Curve {
  const Linear();

  double transform(double t) {
    return t;
  }
}

class Interval implements Curve {
  final double start;
  final double end;

  Interval(this.start, this.end) {
    assert(start >= 0.0);
    assert(start <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
  }

  double transform(double t) {
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class ParabolicFall implements Curve {
  const ParabolicFall();

  double transform(double t) {
    return -t*t + 1;
  }
}

class ParabolicRise implements Curve {
  const ParabolicRise();

  double transform(double t) {
    return -(t-1)*(t-1) + 1;
  }
}

class Cubic implements Curve {
  final double a;
  final double b;
  final double c;
  final double d;

  const Cubic(this.a, this.b, this.c, this.d);

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

double _bounce(double t)
{
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

class BounceInCurve implements Curve {
  const BounceInCurve();

  double transform(double t) {
    return 1.0 - _bounce(1.0 - t);
  }
}

class BounceOutCurve implements Curve {
  const BounceOutCurve();

  double transform(double t) {
    return _bounce(t);
  }
}

class BounceInOutCurve implements Curve {
  const BounceInOutCurve();

  double transform(double t) {
    if (t < 0.5)
      return (1.0 - _bounce(1.0 - t)) * 0.5;
    else
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
  }
}

class ElasticInCurve implements Curve {
  const ElasticInCurve([this.period = 0.4]);
  final double period;

  double transform(double t) {
    double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
  }
}

class ElasticOutCurve implements Curve {
  const ElasticOutCurve([this.period = 0.4]);
  final double period;

  double transform(double t) {
    double s = period / 4.0;
    return math.pow(2.0, -10 * t) * math.sin((t - s) * (math.PI * 2.0) / period) + 1.0;
  }
}

class ElasticInOutCurve implements Curve {
  const ElasticInOutCurve([this.period = 0.4]);
  final double period;

  double transform(double t) {
    t = t * 2;
    double s = period / 4.0;
    t = t - 1.0;
    if (t < 0.0)
      return -0.5 * math.pow(2.0, 10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period);
    else
      return math.pow(2.0, -10.0 * t) * math.sin((t - s) * (math.PI * 2.0) / period) * 0.5 + 1.0;
  }
}

const Linear linear = const Linear();
const Cubic ease = const Cubic(0.25, 0.1, 0.25, 1.0);
const Cubic easeIn = const Cubic(0.42, 0.0, 1.0, 1.0);
const Cubic easeOut = const Cubic(0.0, 0.0, 0.58, 1.0);
const Cubic easeInOut = const Cubic(0.42, 0.0, 0.58, 1.0);
const ParabolicRise parabolicRise = const ParabolicRise();
const ParabolicFall parabolicFall = const ParabolicFall();
const BounceInCurve bounceIn = const BounceInCurve();
const BounceOutCurve bounceOut = const BounceOutCurve();
const BounceInOutCurve bounceInOut = const BounceInOutCurve();
const ElasticInCurve elasticIn = const ElasticInCurve();
const ElasticOutCurve elasticOut = const ElasticOutCurve();
const ElasticInOutCurve elasticInOut = const ElasticInOutCurve();
