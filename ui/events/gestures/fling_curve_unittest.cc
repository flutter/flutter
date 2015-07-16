// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gestures/fling_curve.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/frame_time.h"

namespace ui {

TEST(FlingCurveTest, Basic) {
  const gfx::Vector2dF velocity(0, 5000);
  base::TimeTicks now = gfx::FrameTime::Now();
  FlingCurve curve(velocity, now);

  gfx::Vector2dF delta;
  EXPECT_TRUE(curve.ComputeScrollDeltaAtTime(
      now + base::TimeDelta::FromMilliseconds(20), &delta));
  EXPECT_EQ(0, delta.x());
  EXPECT_NEAR(delta.y(), 96, 1);

  EXPECT_TRUE(curve.ComputeScrollDeltaAtTime(
      now + base::TimeDelta::FromMilliseconds(250), &delta));
  EXPECT_EQ(0, delta.x());
  EXPECT_NEAR(delta.y(), 705, 1);

  EXPECT_FALSE(curve.ComputeScrollDeltaAtTime(
      now + base::TimeDelta::FromSeconds(10), &delta));
  EXPECT_EQ(0, delta.x());
  EXPECT_NEAR(delta.y(), 392, 1);

  EXPECT_FALSE(curve.ComputeScrollDeltaAtTime(
      now + base::TimeDelta::FromSeconds(20), &delta));
  EXPECT_TRUE(delta.IsZero());
}

}  // namespace ui
