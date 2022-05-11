// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Same as [num.clamp] but optimized for non-null [double].  This is roughly 4x
/// faster than using [num.clamp].
double clampDouble(double x, double min, double max) {
  assert(min <= max && !max.isNaN && !min.isNaN);
  if (x < min) {
    return min;
  } else if (x > max) {
    return max;
  } else if (x.isNaN) {
    return max;
  } else {
    return x;
  }
}
