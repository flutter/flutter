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

class OverscrollCurve extends ScrollCurve {
  double apply(double scrollOffset, double scrollDelta) {
    double newScrollOffset = scrollOffset + scrollDelta;
    if (newScrollOffset < 0.0) {
      // If we're overscrolling, we want move the scroll offset 2x slower than
      // we would otherwise. Therefore, we "rewind" the newScrollOffset by half
      // the amount that we moved it above. Notice that we clap the "old" value
      // to 0.0 so that we only reduce the portion of scrollDelta that's applied
      // beyond 0.0.
      newScrollOffset -= (newScrollOffset - math.min(0.0, scrollOffset)) / 2.0;
    }
    return newScrollOffset;
  }
}
