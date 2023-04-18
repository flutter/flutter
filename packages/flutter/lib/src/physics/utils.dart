// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether two doubles are within a given distance of each other.
///
/// The `epsilon` argument must be positive and not null.
/// The `a` and `b` arguments may be null. A null value is only considered
/// near-equal to another null value.
bool nearEqual(final double? a, final double? b, final double epsilon) {
  assert(epsilon >= 0.0);
  if (a == null || b == null) {
    return a == b;
  }
  return (a > (b - epsilon)) && (a < (b + epsilon)) || a == b;
}

/// Whether a double is within a given distance of zero.
///
/// The epsilon argument must be positive.
bool nearZero(final double a, final double epsilon) => nearEqual(a, 0.0, epsilon);
