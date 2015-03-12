// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

abstract class ScrollCurve {
  // Returns the new scroll offset.
  double apply(double scrollOffset, double scrollDelta);
}

class BoundedScrollCurve extends ScrollCurve {
  double minOffset;
  double maxOffset;

  BoundedScrollCurve({this.minOffset: 0.0, this.maxOffset});

  double apply(double scrollOffset, double scrollDelta) {
    double newScrollOffset = scrollOffset + scrollDelta;
    if (minOffset != null)
      newScrollOffset = math.max(minOffset, newScrollOffset);
    if (maxOffset != null)
      newScrollOffset = math.min(maxOffset, newScrollOffset);
    return newScrollOffset;
  }
}
