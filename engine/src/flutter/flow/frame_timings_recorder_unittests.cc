// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/frame_timings.h"

#include <thread>

#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(FrameTimingsRecorderTest, RecordVsync) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();
  const auto st = fml::TimePoint::Now();
  const auto en = st + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordVsync(st, en);

  ASSERT_EQ(st, recorder->GetVsyncStartTime());
  ASSERT_EQ(en, recorder->GetVsyncTargetTime());
}

TEST(FrameTimingsRecorderTest, RecordBuildTimes) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  const auto st = fml::TimePoint::Now();
  const auto en = st + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordVsync(st, en);

  const auto build_start = fml::TimePoint::Now();
  const auto build_end = build_start + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordBuildStart(build_start);
  recorder->RecordBuildEnd(build_end);

  ASSERT_EQ(build_start, recorder->GetBuildStartTime());
  ASSERT_EQ(build_end, recorder->GetBuildEndTime());
}

TEST(FrameTimingsRecorderTest, RecordRasterTimes) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  const auto st = fml::TimePoint::Now();
  const auto en = st + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordVsync(st, en);

  const auto build_start = fml::TimePoint::Now();
  const auto build_end = build_start + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordBuildStart(build_start);
  recorder->RecordBuildEnd(build_end);

  using namespace std::chrono_literals;

  const auto raster_start = fml::TimePoint::Now();
  recorder->RecordRasterStart(raster_start);
  const auto before_raster_end_wall_time = fml::TimePoint::CurrentWallTime();
  std::this_thread::sleep_for(1ms);
  const auto timing = recorder->RecordRasterEnd();
  std::this_thread::sleep_for(1ms);
  const auto after_raster_end_wall_time = fml::TimePoint::CurrentWallTime();

  ASSERT_EQ(raster_start, recorder->GetRasterStartTime());
  ASSERT_GT(recorder->GetRasterEndWallTime(), before_raster_end_wall_time);
  ASSERT_LT(recorder->GetRasterEndWallTime(), after_raster_end_wall_time);
  ASSERT_EQ(recorder->GetFrameNumber(), timing.GetFrameNumber());
}

// Windows and Fuchsia don't allow testing with killed by signal.
#if !defined(OS_FUCHSIA) && !defined(OS_WIN) && \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG)

TEST(FrameTimingsRecorderTest, ThrowWhenRecordBuildBeforeVsync) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  const auto build_start = fml::TimePoint::Now();
  EXPECT_EXIT(recorder->RecordBuildStart(build_start),
              ::testing::KilledBySignal(SIGABRT),
              "Check failed: state_ == State::kVsync.");
}

TEST(FrameTimingsRecorderTest, ThrowWhenRecordRasterBeforeBuildEnd) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  const auto st = fml::TimePoint::Now();
  const auto en = st + fml::TimeDelta::FromMillisecondsF(16);
  recorder->RecordVsync(st, en);

  const auto raster_start = fml::TimePoint::Now();
  EXPECT_EXIT(recorder->RecordRasterStart(raster_start),
              ::testing::KilledBySignal(SIGABRT),
              "Check failed: state_ == State::kBuildEnd.");
}

#endif

TEST(FrameTimingsRecorderTest, RecordersHaveUniqueFrameNumbers) {
  auto recorder1 = std::make_unique<FrameTimingsRecorder>();
  auto recorder2 = std::make_unique<FrameTimingsRecorder>();

  ASSERT_TRUE(recorder2->GetFrameNumber() > recorder1->GetFrameNumber());
}

TEST(FrameTimingsRecorderTest, ClonedHasSameFrameNumber) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  const auto now = fml::TimePoint::Now();
  recorder->RecordVsync(now, now);

  auto cloned = recorder->CloneUntil(FrameTimingsRecorder::State::kVsync);
  ASSERT_EQ(recorder->GetFrameNumber(), cloned->GetFrameNumber());
}

TEST(FrameTimingsRecorderTest, FrameNumberTraceArgIsValid) {
  auto recorder = std::make_unique<FrameTimingsRecorder>();

  char buff[50];
  sprintf(buff, "%d", static_cast<int>(recorder->GetFrameNumber()));
  std::string actual_arg = buff;
  std::string expected_arg = recorder->GetFrameNumberTraceArg();

  ASSERT_EQ(actual_arg, expected_arg);
}

}  // namespace testing
}  // namespace flutter
