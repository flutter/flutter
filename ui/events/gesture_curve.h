// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURE_CURVE_H_
#define UI_EVENTS_GESTURE_CURVE_H_

#include "base/time/time.h"
#include "ui/gfx/geometry/vector2d_f.h"

namespace ui {

// An abstraction of curve-based gesture motion, allowing platform-specific
// motion tailoring.
class EVENTS_BASE_EXPORT GestureCurve {
 public:
  virtual ~GestureCurve() {}

  // The output |offset| represents the total movement of the curve from its
  // start until |time|.
  // The output |velocity| represents the instantenous velocity at |time|.
  // Returns false if |time| exceeds the fling duration, in which case
  // the terminal offset will be reported.
  virtual bool ComputeScrollOffset(base::TimeTicks time,
                                   gfx::Vector2dF* offset,
                                   gfx::Vector2dF* velocity) = 0;
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURE_CURVE_H_
