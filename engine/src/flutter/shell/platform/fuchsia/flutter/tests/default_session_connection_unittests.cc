// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/policy/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/async-loop/default.h>
#include <lib/sys/cpp/component_context.h>

#include "flutter/shell/platform/fuchsia/flutter/default_session_connection.h"
#include "flutter/shell/platform/fuchsia/flutter/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/runner.h"
#include "gtest/gtest.h"

using namespace flutter_runner;

namespace flutter_runner_test {

static fml::TimePoint TimePointFromInt(int i) {
  return fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(i));
}
static fml::TimeDelta TimeDeltaFromInt(int i) {
  return fml::TimeDelta::FromNanoseconds(i);
}
static int TimePointToInt(fml::TimePoint time) {
  return time.ToEpochDelta().ToNanoseconds();
}

static fuchsia::scenic::scheduling::PresentationInfo CreatePresentationInfo(
    zx_time_t latch_point,
    zx_time_t presentation_time) {
  fuchsia::scenic::scheduling::PresentationInfo info;

  info.set_latch_point(latch_point);
  info.set_presentation_time(presentation_time);
  return info;
}

class DefaultSessionConnectionTest : public ::testing::Test {
 public:
  void SetUp() override {
    context_ = sys::ComponentContext::CreateAndServeOutgoingDirectory();
    scenic_ = context_->svc()->Connect<fuchsia::ui::scenic::Scenic>();
    presenter_ = context_->svc()->Connect<fuchsia::ui::policy::Presenter>();

    FML_CHECK(ZX_OK == loop_.StartThread("DefaultSessionConnectionTestThread",
                                         &fidl_thread_));

    auto session_listener_request = session_listener_.NewRequest();

    scenic_->CreateSession(session_.NewRequest(), session_listener_.Bind());

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
  thrd_t fidl_thread_;
};

TEST_F(DefaultSessionConnectionTest, SimplePresent) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 3, fml::TimeDelta::FromSeconds(0));

  for (int i = 0; i < 200; ++i) {
    session_connection.Present();
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }

  EXPECT_GT(num_presents_handled, 0u);
}

TEST_F(DefaultSessionConnectionTest, BatchedPresent) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 3, fml::TimeDelta::FromSeconds(0));

  for (int i = 0; i < 200; ++i) {
    session_connection.Present();
    if (i % 10 == 9) {
      std::this_thread::sleep_for(std::chrono::milliseconds(20));
    }
  }

  EXPECT_GT(num_presents_handled, 0u);
}

TEST_F(DefaultSessionConnectionTest, AwaitVsync) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 3, fml::TimeDelta::FromSeconds(0));

  uint64_t await_vsyncs_handled = 0;

  for (int i = 0; i < 5; ++i) {
    session_connection.Present();
    session_connection.AwaitVsync(
        [&await_vsyncs_handled](auto...) { await_vsyncs_handled++; });
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  EXPECT_GT(num_presents_handled, 0u);
  EXPECT_GT(await_vsyncs_handled, 0u);
}

TEST_F(DefaultSessionConnectionTest, EnsureBackpressureForAwaitVsync) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 0, fml::TimeDelta::FromSeconds(0));

  uint64_t await_vsyncs_handled = 0;

  for (int i = 0; i < 5; ++i) {
    session_connection.Present();
    session_connection.AwaitVsync(
        [&await_vsyncs_handled](auto...) { await_vsyncs_handled++; });
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  EXPECT_EQ(num_presents_handled, 1u);
  EXPECT_EQ(await_vsyncs_handled, 0u);
}

TEST_F(DefaultSessionConnectionTest, SecondaryCallbackShouldFireRegardless) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 0, fml::TimeDelta::FromSeconds(0));

  // We're going to expect *only* secondary callbacks to be triggered.
  uint64_t await_vsyncs_handled = 0;
  uint64_t await_vsync_for_secondary_callbacks_handled = 0;

  for (int i = 0; i < 5; ++i) {
    session_connection.Present();
    session_connection.AwaitVsync(
        [&await_vsyncs_handled](auto...) { await_vsyncs_handled++; });
    session_connection.AwaitVsyncForSecondaryCallback(
        [&await_vsync_for_secondary_callbacks_handled](auto...) {
          await_vsync_for_secondary_callbacks_handled++;
        });
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  EXPECT_EQ(num_presents_handled, 1u);
  EXPECT_EQ(await_vsyncs_handled, 0u);
  EXPECT_GT(await_vsync_for_secondary_callbacks_handled, 0u);
}

TEST_F(DefaultSessionConnectionTest, AwaitVsyncBackpressureRelief) {
  fml::closure on_session_error_callback = []() { FML_CHECK(false); };

  uint64_t num_presents_handled = 0;
  on_frame_presented_event on_frame_presented_callback =
      [&num_presents_handled](
          fuchsia::scenic::scheduling::FramePresentedInfo info) {
        num_presents_handled += info.presentation_infos.size();
      };

  flutter_runner::DefaultSessionConnection session_connection(
      "debug label", std::move(session_), on_session_error_callback,
      on_frame_presented_callback, 1, fml::TimeDelta::FromSeconds(0));

  uint64_t await_vsyncs_handled = 0;

  // Max out our present budget.
  for (int i = 0; i < 5; ++i) {
    session_connection.Present();
  }

  // AwaitVsyncs().
  for (int i = 0; i < 5; ++i) {
    session_connection.AwaitVsync(
        [&await_vsyncs_handled](auto...) { await_vsyncs_handled++; });
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  EXPECT_GT(num_presents_handled, 0u);
  EXPECT_GT(await_vsyncs_handled, 0u);
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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
      DefaultSessionConnection::CalculateNextLatchPoint(
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

TEST(SnapToNextPhaseTest, SnapOverlapsWithNow) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(10);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync =
      flutter_runner::DefaultSessionConnection::SnapToNextPhase(
          now, last_presentation_time, delta);

  EXPECT_EQ(now + delta, next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNow) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(9);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync =
      flutter_runner::DefaultSessionConnection::SnapToNextPhase(
          now, last_presentation_time, delta);

  // math here: 10 - 9 = 1
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(1), next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNowMultiJump) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(34);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync =
      flutter_runner::DefaultSessionConnection::SnapToNextPhase(
          now, last_presentation_time, delta);

  // zeroes: -34, -24, -14, -4, 6, ...
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(6), next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNowMultiJumpAccountForCeils) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(20);
  const auto delta = fml::TimeDelta::FromNanoseconds(16);
  const auto next_vsync =
      flutter_runner::DefaultSessionConnection::SnapToNextPhase(
          now, last_presentation_time, delta);

  // zeroes: -20, -4, 12, 28, ...
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(12), next_vsync);
}

TEST(GetTargetTimesTest, ScheduleForNextVsync) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(10);
  const fml::TimePoint now = TimePointFromInt(9);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 10);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 20);
}

TEST(GetTargetTimesTest, ScheduleForCurrentVsync_DueToOffset) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(3);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(0);
  const fml::TimePoint now = TimePointFromInt(6);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 7);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 10);
}

TEST(GetTargetTimesTest, ScheduleForFollowingVsync_BecauseOfNow) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(10);
  const fml::TimePoint now = TimePointFromInt(15);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 20);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 30);
}

TEST(GetTargetTimesTest, ScheduleForFollowingVsync_BecauseOfTargettedTime) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(20);
  const fml::TimePoint now = TimePointFromInt(9);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 20);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 30);
}

TEST(GetTargetTimesTest, ScheduleForDistantVsync_BecauseOfTargettedTime) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(60);
  const fml::TimePoint now = TimePointFromInt(9);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 60);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 70);
}

TEST(GetTargetTimesTest, ScheduleForFollowingVsync_WithSlightVsyncDrift) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);

  // Even though it appears as if the next vsync is at time 40, we should still
  // present at time 50.
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(37);
  const fml::TimePoint now = TimePointFromInt(9);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 40);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 50);
}

TEST(GetTargetTimesTest, ScheduleForAnOffsetFromVsync) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(4);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);
  const fml::TimePoint last_targeted_vsync = TimePointFromInt(10);
  const fml::TimePoint now = TimePointFromInt(9);
  const fml::TimePoint next_vsync = TimePointFromInt(10);

  const auto target_times =
      flutter_runner::DefaultSessionConnection::GetTargetTimes(
          vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

  EXPECT_EQ(TimePointToInt(target_times.frame_start), 16);
  EXPECT_EQ(TimePointToInt(target_times.frame_target), 20);
}

TEST(GetTargetTimesTest, ScheduleMultipleTimes) {
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);

  fml::TimePoint last_targeted_vsync = TimePointFromInt(0);
  fml::TimePoint now = TimePointFromInt(5);
  fml::TimePoint next_vsync = TimePointFromInt(10);

  for (int i = 0; i < 100; ++i) {
    const auto target_times =
        flutter_runner::DefaultSessionConnection::GetTargetTimes(
            vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

    EXPECT_EQ(TimePointToInt(target_times.frame_start), 10 * (i + 1));
    EXPECT_EQ(TimePointToInt(target_times.frame_target), 10 * (i + 2));

    // Simulate the passage of time.
    now = now + vsync_interval;
    next_vsync = next_vsync + vsync_interval;
    last_targeted_vsync = target_times.frame_target;
  }
}

TEST(GetTargetTimesTest, ScheduleMultipleTimes_WithDelayedWakeups) {
  // It is often the case that Flutter does not wake up when it intends to due
  // to CPU contention. This test has DefaultSessionConnection wake up to
  // schedule 0-4ns after when |now| should be - and we verify that the results
  // should be the same as if there were no delay.
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);

  fml::TimePoint last_targeted_vsync = TimePointFromInt(0);
  fml::TimePoint now = TimePointFromInt(5);
  fml::TimePoint next_vsync = TimePointFromInt(10);

  for (int i = 0; i < 100; ++i) {
    const auto target_times =
        flutter_runner::DefaultSessionConnection::GetTargetTimes(
            vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

    const auto target_times_delay =
        flutter_runner::DefaultSessionConnection::GetTargetTimes(
            vsync_offset, vsync_interval, last_targeted_vsync,
            now + TimeDeltaFromInt(i % 5), next_vsync);

    EXPECT_EQ(TimePointToInt(target_times.frame_start),
              TimePointToInt(target_times_delay.frame_start));
    EXPECT_EQ(TimePointToInt(target_times.frame_target),
              TimePointToInt(target_times_delay.frame_target));

    // Simulate the passage of time.
    now = now + vsync_interval;
    next_vsync = next_vsync + vsync_interval;
    last_targeted_vsync = target_times.frame_target;
  }
}
// static fuchsia::scenic::scheduling::PresentationInfo UpdatePresentationInfo(
//   fuchsia::scenic::scheduling::FuturePresentationTimes future_info,
//   fuchsia::scenic::scheduling::PresentationInfo& presentation_info);

TEST(UpdatePresentationInfoTest, SingleUpdate) {
  std::vector<fuchsia::scenic::scheduling::PresentationInfo>
      future_presentations = {};

  // Update the |vsync_info|.
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/5, /*presentation_time=*/10));

  fuchsia::scenic::scheduling::FuturePresentationTimes future_info;
  future_info.future_presentations = std::move(future_presentations);
  future_info.remaining_presents_in_flight_allowed = 1;

  fuchsia::scenic::scheduling::PresentationInfo presentation_info;
  presentation_info.set_presentation_time(0);

  fuchsia::scenic::scheduling::PresentationInfo new_presentation_info =
      flutter_runner::DefaultSessionConnection::UpdatePresentationInfo(
          std::move(future_info), presentation_info);

  EXPECT_EQ(new_presentation_info.presentation_time(), 10);
}

TEST(UpdatePresentationInfoTest, MultipleUpdates) {
  std::vector<fuchsia::scenic::scheduling::PresentationInfo>
      future_presentations = {};

  // Update the |vsync_info|.
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/15, /*presentation_time=*/20));
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/25, /*presentation_time=*/30));
  fuchsia::scenic::scheduling::FuturePresentationTimes future_info;
  future_info.future_presentations = std::move(future_presentations);
  future_info.remaining_presents_in_flight_allowed = 1;

  fuchsia::scenic::scheduling::PresentationInfo presentation_info;
  presentation_info.set_presentation_time(0);

  fuchsia::scenic::scheduling::PresentationInfo new_presentation_info =
      flutter_runner::DefaultSessionConnection::UpdatePresentationInfo(
          std::move(future_info), presentation_info);

  EXPECT_EQ(new_presentation_info.presentation_time(), 20);

  // Clear and re-try with more future times!
  future_presentations.clear();
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/15, /*presentation_time=*/20));
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/25, /*presentation_time=*/30));
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/35, /*presentation_time=*/40));
  future_presentations.push_back(
      CreatePresentationInfo(/*latch_point=*/45, /*presentation_time=*/50));
  future_info.future_presentations = std::move(future_presentations);
  future_info.remaining_presents_in_flight_allowed = 1;

  new_presentation_info =
      flutter_runner::DefaultSessionConnection::UpdatePresentationInfo(
          std::move(future_info), new_presentation_info);

  EXPECT_EQ(new_presentation_info.presentation_time(), 30);
}

}  // namespace flutter_runner_test
