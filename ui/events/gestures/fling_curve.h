// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_GESTURES_FLING_CURVE_H_
#define UI_EVENTS_GESTURES_FLING_CURVE_H_

#include "base/time/time.h"
#include "ui/events/events_base_export.h"
#include "ui/events/gesture_curve.h"
#include "ui/gfx/geometry/point_f.h"
#include "ui/gfx/geometry/vector2d_f.h"

namespace ui {

// FlingCurve can be used to scroll a UI element suitable for touch screen-based
// flings.
class EVENTS_BASE_EXPORT FlingCurve : public GestureCurve {
 public:
  FlingCurve(const gfx::Vector2dF& velocity, base::TimeTicks start_timestamp);
  ~FlingCurve() override;

  // GestureCurve implementation.
  bool ComputeScrollOffset(base::TimeTicks time,
                           gfx::Vector2dF* offset,
                           gfx::Vector2dF* velocity) override;

  // In contrast to |ComputeScrollOffset()|, this method is stateful and
  // returns the *change* in scroll offset between successive calls.
  // Returns true as long as the curve is still active and requires additional
  // animation ticks.
  bool ComputeScrollDeltaAtTime(base::TimeTicks current, gfx::Vector2dF* delta);

 private:
  const float curve_duration_;
  const base::TimeTicks start_timestamp_;

  gfx::Vector2dF displacement_ratio_;
  gfx::Vector2dF cumulative_scroll_;
  base::TimeTicks previous_timestamp_;
  float time_offset_;
  float position_offset_;

  DISALLOW_COPY_AND_ASSIGN(FlingCurve);
};

}  // namespace ui

#endif  // UI_EVENTS_GESTURES_FLING_CURVE_H_
