// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_FRAME_TIME_H
#define UI_GFX_FRAME_TIME_H

#include "base/time/time.h"
#include "base/logging.h"

namespace gfx {

// FrameTime::Now() should be used to get timestamps with a timebase that
// is consistent across the graphics stack.
class FrameTime {
 public:
  static base::TimeTicks Now() {
    return base::TimeTicks::Now();
  }

  static bool TimestampsAreHighRes() {
    // This should really return base::TimeTicks::IsHighResNowFastAndReliable();
    // Returning false makes sure we are only using low-res timestamps until we
    // use FrameTime everywhere we need to. See crbug.com/315334
    return false;
  }
};

}

#endif // UI_GFX_FRAME_TIME_H
