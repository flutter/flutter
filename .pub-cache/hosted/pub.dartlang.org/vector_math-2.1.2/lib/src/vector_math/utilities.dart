// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math;

/// Convert [radians] to degrees.
double degrees(double radians) => radians * radians2Degrees;

/// Convert [degrees] to radians.
double radians(double degrees) => degrees * degrees2Radians;

/// Interpolate between [min] and [max] with the amount of [a] using a linear
/// interpolation. The computation is equivalent to the GLSL function mix.
double mix(double min, double max, double a) => min + a * (max - min);

/// Do a smooth step (hermite interpolation) interpolation with [edge0] and
/// [edge1] by [amount]. The computation is equivalent to the GLSL function
/// smoothstep.
double smoothStep(double edge0, double edge1, double amount) {
  final t = ((amount - edge0) / (edge1 - edge0)).clamp(0.0, 1.0).toDouble();

  return t * t * (3.0 - 2.0 * t);
}

/// Do a catmull rom spline interpolation with [edge0], [edge1], [edge2] and
/// [edge3] by [amount].
double catmullRom(double edge0, double edge1, double edge2, double edge3,
        double amount) =>
    0.5 *
    ((2.0 * edge1) +
        (-edge0 + edge2) * amount +
        (2.0 * edge0 - 5.0 * edge1 + 4.0 * edge2 - edge3) * (amount * amount) +
        (-edge0 + 3.0 * edge1 - 3.0 * edge2 + edge3) *
            (amount * amount * amount));
