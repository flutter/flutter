// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <lib/async-loop/default.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>

#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/policy/cpp/fidl.h>

#include "flutter/shell/platform/fuchsia/flutter/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/runner.h"
#include "flutter/shell/platform/fuchsia/flutter/session_connection.h"

using namespace flutter_runner;

namespace flutter_runner_test {

class SessionConnectionTest : public ::testing::Test {
 public:
  void SetUp() override {
    context_ = sys::ComponentContext::CreateAndServeOutgoingDirectory();
    scenic_ = context_->svc()->Connect<fuchsia::ui::scenic::Scenic>();
    presenter_ = context_->svc()->Connect<fuchsia::ui::policy::Presenter>();

    FML_CHECK(ZX_OK ==
              loop_.StartThread("SessionConnectionTestThread", &fidl_thread_));

    auto session_listener_request = session_listener_.NewRequest();
    auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
    view_token_ = std::move(view_token);

    scenic_->CreateSession(session_.NewRequest(), session_listener_.Bind());
    presenter_->PresentOrReplaceView(std::move(view_holder_token), nullptr);

    FML_CHECK(zx::event::create(0, &vsync_event_) == ZX_OK);

    // Ensure Scenic has had time to wake up before the test logic begins.
    // TODO(61768) Find a better solution than sleeping periodically checking a
    // condition.
    int scenic_initialized = false;
    scenic_->GetDisplayInfo(
        [&scenic_initialized](fuchsia::ui::gfx::DisplayInfo display_info) {
          scenic_initialized = true;
        });
    while (!scenic_initialized) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
  }
  // Warning: Initialization order matters here. |loop_| must be initialized
  // before |SetUp()| so that we have a dispatcher already initialized.
  async::Loop loop_ = async::Loop(&kAsyncLoopConfigAttachToCurrentThread);

  std::unique_ptr<sys::ComponentContext> context_;
  fuchsia::ui::scenic::ScenicPtr scenic_;
  fuchsia::ui::policy::PresenterPtr presenter_;

  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session_;
  fidl::InterfaceHandle<fuchsia::ui::scenic::SessionListener> session_listener_;
  fuchsia::ui::views::ViewToken view_token_;
  zx::event vsync_event_;
  thrd_t fidl_thread_;
};

TEST_F(SessionConnectionTest, SimplePresentTest) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::SessionConnection session_connection(
      "debug label", std::move(view_token_), scenic::ViewRefPair::New(),
      std::move(session_), on_session_error_callback,
      on_frame_presented_callback, vsync_event_.get());

  for (int i = 0; i < 200; ++i) {
    session_connection.Present(nullptr);
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }

  EXPECT_GT(num_presents_handled, 0u);
}

TEST_F(SessionConnectionTest, BatchedPresentTest) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::SessionConnection session_connection(
      "debug label", std::move(view_token_), scenic::ViewRefPair::New(),
      std::move(session_), on_session_error_callback,
      on_frame_presented_callback, vsync_event_.get());

  for (int i = 0; i < 200; ++i) {
    session_connection.Present(nullptr);
    if (i % 10 == 9) {
      std::this_thread::sleep_for(std::chrono::milliseconds(20));
    }
  }

  EXPECT_GT(num_presents_handled, 0u);
}

static fml::TimePoint TimePointFromInt(int i) {
  return fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(i));
}
static fml::TimeDelta TimeDeltaFromInt(int i) {
  return fml::TimeDelta::FromNanoseconds(i);
}
static int TimePointToInt(fml::TimePoint time) {
  return time.ToEpochDelta().ToNanoseconds();
}

// The first set of tests has an empty |future_presentation_infos| passed in.
// Therefore these tests are to ensure that on startup and after not presenting
// for some time that we have correct, reasonable behavior.
TEST(CalculateNextLatchPointTest, PresentAsSoonAsPossible) {
  fml::TimePoint present_requested_time = TimePointFromInt(0);
  fml::TimePoint now = TimePointFromInt(0);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(0);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(0);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {};

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point), TimePointToInt(now));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, LongFrameBuildTime) {
  fml::TimePoint present_requested_time = TimePointFromInt(500);
  fml::TimePoint now = TimePointFromInt(600);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(0);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(2500);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {};

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(flutter_frame_build_time, vsync_interval);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 3)));

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, DelayedPresentRequestWithLongFrameBuildTime) {
  fml::TimePoint present_requested_time = TimePointFromInt(0);
  fml::TimePoint now = TimePointFromInt(1500);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(0);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(2000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {};

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(flutter_frame_build_time, vsync_interval);
  EXPECT_GT(now, present_requested_time + vsync_interval);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point), TimePointToInt(now));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, LastLastPointTargetedLate) {
  fml::TimePoint present_requested_time = TimePointFromInt(2000);
  fml::TimePoint now = TimePointFromInt(2000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(2600);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(1000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {};

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(last_latch_point_targeted, present_requested_time);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

// This set of tests provides (latch_point, vsync_time) pairs in
// |future_presentation_infos|. This tests steady state behavior where we're
// presenting frames virtually every vsync interval.

TEST(CalculateNextLatchPointTest, SteadyState_OnTimeFrames) {
  fml::TimePoint present_requested_time = TimePointFromInt(5000);
  fml::TimePoint now = TimePointFromInt(5000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(4500);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(1000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(3500), TimePointFromInt(4000)},
          {TimePointFromInt(4500), TimePointFromInt(5000)},
          {TimePointFromInt(5500), TimePointFromInt(6000)},
          {TimePointFromInt(6500), TimePointFromInt(7000)},
          {TimePointFromInt(7500), TimePointFromInt(8000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 6500);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, SteadyState_LongFrameBuildTimes) {
  fml::TimePoint present_requested_time = TimePointFromInt(5000);
  fml::TimePoint now = TimePointFromInt(5000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(4500);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(2000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(3500), TimePointFromInt(4000)},
          {TimePointFromInt(4500), TimePointFromInt(5000)},
          {TimePointFromInt(5500), TimePointFromInt(6000)},
          {TimePointFromInt(6500), TimePointFromInt(7000)},
          {TimePointFromInt(7500), TimePointFromInt(8000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(flutter_frame_build_time, vsync_interval);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 3)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 7500);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, SteadyState_LateLastLatchPointTargeted) {
  fml::TimePoint present_requested_time = TimePointFromInt(5000);
  fml::TimePoint now = TimePointFromInt(5000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(6500);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(1000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(4500), TimePointFromInt(5000)},
          {TimePointFromInt(5500), TimePointFromInt(6000)},
          {TimePointFromInt(6500), TimePointFromInt(7000)},
          {TimePointFromInt(7500), TimePointFromInt(8000)},
          {TimePointFromInt(8500), TimePointFromInt(9000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(last_latch_point_targeted, now + vsync_interval);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 6500);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest,
     SteadyState_DelayedPresentRequestWithLongFrameBuildTime) {
  fml::TimePoint present_requested_time = TimePointFromInt(4000);
  fml::TimePoint now = TimePointFromInt(5500);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(3500);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(2000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(4500), TimePointFromInt(5000)},
          {TimePointFromInt(5500), TimePointFromInt(6000)},
          {TimePointFromInt(6500), TimePointFromInt(7000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  EXPECT_GT(flutter_frame_build_time, vsync_interval);
  EXPECT_GT(now, present_requested_time + vsync_interval);

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 6500);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, SteadyState_FuzzyLatchPointsBeforeTarget) {
  fml::TimePoint present_requested_time = TimePointFromInt(4000);
  fml::TimePoint now = TimePointFromInt(4000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(5490);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(1000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(4510), TimePointFromInt(5000)},
          {TimePointFromInt(5557), TimePointFromInt(6000)},
          {TimePointFromInt(6482), TimePointFromInt(7000)},
          {TimePointFromInt(7356), TimePointFromInt(8000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + vsync_interval));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 5557);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}

TEST(CalculateNextLatchPointTest, SteadyState_FuzzyLatchPointsAfterTarget) {
  fml::TimePoint present_requested_time = TimePointFromInt(4000);
  fml::TimePoint now = TimePointFromInt(4000);
  fml::TimePoint last_latch_point_targeted = TimePointFromInt(5557);
  fml::TimeDelta flutter_frame_build_time = TimeDeltaFromInt(1000);
  fml::TimeDelta vsync_interval = TimeDeltaFromInt(1000);
  std::deque<std::pair<fml::TimePoint, fml::TimePoint>>
      future_presentation_infos = {
          {TimePointFromInt(4510), TimePointFromInt(5000)},
          {TimePointFromInt(5490), TimePointFromInt(6000)},
          {TimePointFromInt(6482), TimePointFromInt(7000)},
          {TimePointFromInt(7356), TimePointFromInt(8000)},
      };

  // Assertions about given values.
  EXPECT_GE(now, present_requested_time);
  EXPECT_GE(flutter_frame_build_time, TimeDeltaFromInt(0));
  EXPECT_GT(vsync_interval, TimeDeltaFromInt(0));

  fml::TimePoint calculated_latch_point =
      SessionConnection::CalculateNextLatchPoint(
          present_requested_time, now, last_latch_point_targeted,
          flutter_frame_build_time, vsync_interval, future_presentation_infos);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 2)));
  EXPECT_LE(TimePointToInt(calculated_latch_point),
            TimePointToInt(now + (vsync_interval * 3)));
  EXPECT_EQ(TimePointToInt(calculated_latch_point), 6482);

  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(present_requested_time + flutter_frame_build_time));
  EXPECT_GE(TimePointToInt(calculated_latch_point),
            TimePointToInt(last_latch_point_targeted));
}
}  // namespace flutter_runner_test
