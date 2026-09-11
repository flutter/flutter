// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// Whether the magnitude of [offset] is greater than [threshold].
///
/// This is equivalent to `offset.distance > threshold` for a non-negative
/// [threshold], but avoids computing the square root used by `Offset.distance`.
bool offsetExceedsThreshold(Offset offset, double threshold) {
  assert(threshold >= 0.0);
  return offset.distanceSquared > threshold * threshold;
}
