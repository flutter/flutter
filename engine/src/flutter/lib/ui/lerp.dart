// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10

part of dart.ui;

/// Linearly interpolate between two numbers.
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null)
    return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t as double;
}

/// Linearly interpolate between two doubles.
///
/// Same as [lerpDouble] but specialized for non-null `double` type.
double _lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

/// Linearly interpolate between two integers.
///
/// Same as [lerpDouble] but specialized for non-null `int` type.
double _lerpInt(int a, int b, double t) {
  return a + (b - a) * t;
}

/// Same as [num.clamp] but specialized for non-null [int].
int _clampInt(int value, int min, int max) {
  assert(min <= max);
  if (value < min) {
    return min;
  } else if (value > max) {
    return max;
  } else {
    return value;
  }
}
