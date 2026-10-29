// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vsync_timing.h"

#include "gtest/gtest.h"

TEST(FlVsyncTimingTest, PreserveHistoryPredictionAndConvertClockUnits) {
  const auto timing = fl_vsync_timing_from_refresh_info(1000000, 6944, 1004000);
  EXPECT_EQ(timing.frame_start_ns, 1000000000u);
  EXPECT_EQ(timing.frame_target_ns, 1004000000u);
  EXPECT_EQ(timing.refresh_interval_us, 6944);
}

TEST(FlVsyncTimingTest, MissingPredictionUsesDisplayInterval) {
  for (gint64 interval : {16667, 8333, 6944}) {
    const auto timing = fl_vsync_timing_from_refresh_info(1000000, interval, 0);
    EXPECT_EQ(timing.frame_target_ns - timing.frame_start_ns,
              static_cast<uint64_t>(interval) * 1000u);
    EXPECT_EQ(timing.refresh_interval_us, interval);
  }
}

TEST(FlVsyncTimingTest, StalePredictionNeverBecomesAnExpiredFrameTarget) {
  for (gint64 prediction : {999000, 1000000}) {
    const auto timing =
        fl_vsync_timing_from_refresh_info(1000000, 8333, prediction);
    EXPECT_EQ(timing.frame_target_ns, 1008333000u);
  }
}

TEST(FlVsyncTimingTest, UnknownIntervalUsesConservativeFallback) {
  for (gint64 interval : {0, -1}) {
    const auto timing = fl_vsync_timing_from_refresh_info(1000000, interval, 0);
    EXPECT_EQ(timing.frame_target_ns - timing.frame_start_ns, 16667000u);
    EXPECT_EQ(timing.refresh_interval_us, 16667);
  }
}
