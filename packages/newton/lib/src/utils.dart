// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether two doubles are within a given distance of each other.
///
/// The epsilon argument must be positive.
bool nearEqual(double a, double b, double epsilon) {
  assert(epsilon >= 0.0);
  return (a > (b - epsilon)) && (a < (b + epsilon));
}

/// Whether a double is within a given distance of zero.
///
/// The epsilon argument must be positive.
bool nearZero(double a, double epsilon) => nearEqual(a, 0.0, epsilon);
