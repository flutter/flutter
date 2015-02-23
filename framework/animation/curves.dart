// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

const Linear linear = const Linear();
const Cubic ease = const Cubic(0.25, 0.1, 0.25, 1.0);
const Cubic easeIn = const Cubic(0.42, 0.0, 1.0, 1.0);
const Cubic easeOut = const Cubic(0.0, 0.0, 0.58, 1.0);
const Cubic easeInOut = const Cubic(0.42, 0.0, 0.58, 1.0);
