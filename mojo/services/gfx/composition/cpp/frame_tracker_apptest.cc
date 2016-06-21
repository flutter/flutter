// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/gfx/composition/cpp/frame_tracker.h"

#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/system/macros.h"

namespace test {

class FrameTrackerTest : public mojo::test::ApplicationTestBase {
 public:
  FrameTrackerTest() {}
  ~FrameTrackerTest() override {}

 protected:
  mojo::gfx::composition::FrameTracker frame_tracker_;

  void Update(int64_t frame_time,
              uint64_t frame_interval,
              int64_t frame_deadline,
              int64_t presentation_time,
              MojoTimeTicks now) {
    mojo::gfx::composition::FrameInfo frame_info;
    frame_info.frame_time = frame_time;
    frame_info.frame_interval = frame_interval;
    frame_info.frame_deadline = frame_deadline;
    frame_info.presentation_time = presentation_time;
    frame_tracker_.Update(frame_info, now);
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(FrameTrackerTest);
};

namespace {

TEST_F(FrameTrackerTest, InitialState) {
  EXPECT_EQ(0u, frame_tracker_.frame_count());
  EXPECT_EQ(0, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(0u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(0, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(0, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, ClearResetsEverything) {
  Update(10, 10u, 10, 10, 10);

  frame_tracker_.Clear();
  EXPECT_EQ(0u, frame_tracker_.frame_count());
  EXPECT_EQ(0, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(0u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(0, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(0, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, TypicalUpdate) {
  // Signalled right at frame time.
  // No corrections.
  Update(12, 10u, 24, 28, 12);
  EXPECT_EQ(1u, frame_tracker_.frame_count());
  EXPECT_EQ(12, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(24, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(28, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());

  // Signalled 1 ms after frame time.
  // No corrections.
  Update(22, 10u, 34, 38, 22 + 1);
  EXPECT_EQ(2u, frame_tracker_.frame_count());
  EXPECT_EQ(22, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(34, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(38, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(10, frame_tracker_.frame_time_delta());

  // Signalled 9 ms after frame time (frame interval is 10 ms).
  // No corrections.
  Update(32, 10u, 44, 48, 32 + 9);
  EXPECT_EQ(3u, frame_tracker_.frame_count());
  EXPECT_EQ(32, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(44, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(48, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(10, frame_tracker_.frame_time_delta());

  // Frame interval changed.
  // No corrections.
  Update(46, 15u, 59, 62, 46 + 2);
  EXPECT_EQ(4u, frame_tracker_.frame_count());
  EXPECT_EQ(46, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(15u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(59, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(62, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(14, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, LagCompensation) {
  // Received signal exactly when next frame should begin.
  // Skip 1 frame.
  Update(12, 10u, 24, 28, 12 + 10);
  EXPECT_EQ(1u, frame_tracker_.frame_count());
  EXPECT_EQ(22, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(34, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(38, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());

  // Received signal 2 ms after next frame should begin.
  // Skip 1 frame.
  Update(32, 10u, 44, 48, 32 + 10 + 2);
  EXPECT_EQ(2u, frame_tracker_.frame_count());
  EXPECT_EQ(42, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(54, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(58, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(20, frame_tracker_.frame_time_delta());

  // Received signal 35 ms after next frame should begin.
  // Skip 4 frames.
  Update(52, 10u, 64, 68, 52 + 10 + 35);
  EXPECT_EQ(3u, frame_tracker_.frame_count());
  EXPECT_EQ(92, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(104, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(108, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(50, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, FrameTimeInPast) {
  // Frame time is in the future.
  // Clamp frame time to present.
  Update(12, 10u, 24, 28, 12 - 1);
  EXPECT_EQ(1u, frame_tracker_.frame_count());
  EXPECT_EQ(11, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(24, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(28, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, FrameDeadlineBehindFrameTime) {
  // Frame deadline is earlier than frame time.
  // Clamp frame deadline time to frame time.
  Update(12, 10u, 12 - 1, 28, 12);
  EXPECT_EQ(1u, frame_tracker_.frame_count());
  EXPECT_EQ(12, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(12, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(28, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, PresentationTimeBehindFrameDeadline) {
  // Presentation time is earlier than frame deadline.
  // Clamp presentation time to frame deadline.
  Update(12, 10u, 24, 24 - 1, 12);
  EXPECT_EQ(1u, frame_tracker_.frame_count());
  EXPECT_EQ(12, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(24, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(24, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, NonMonotonicFrameTime) {
  Update(12, 10u, 24, 28, 12);

  // Frame time is going backwards.
  // Clamp frame time to old frame time.
  Update(10, 10u, 24, 28, 13);
  EXPECT_EQ(2u, frame_tracker_.frame_count());
  EXPECT_EQ(12, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(24, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(28, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(0, frame_tracker_.frame_time_delta());
}

TEST_F(FrameTrackerTest, NonMonotonicPresentationTime) {
  Update(12, 10u, 24, 28, 12);

  // Presentation time is going backwards.
  // Clamp presentation time to old presentation time.
  Update(22, 10u, 26, 27, 22);
  EXPECT_EQ(2u, frame_tracker_.frame_count());
  EXPECT_EQ(22, frame_tracker_.frame_info().frame_time);
  EXPECT_EQ(10u, frame_tracker_.frame_info().frame_interval);
  EXPECT_EQ(26, frame_tracker_.frame_info().frame_deadline);
  EXPECT_EQ(28, frame_tracker_.frame_info().presentation_time);
  EXPECT_EQ(10, frame_tracker_.frame_time_delta());
}

}  // namespace
}  // namespace mojo
