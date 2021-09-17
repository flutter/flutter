// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/gfx_session_connection.h"

#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <lib/async-testing/test_loop.h>
#include <lib/inspect/cpp/inspect.h>

#include <functional>
#include <string>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

#include "fakes/scenic/fake_session.h"

using fuchsia::scenic::scheduling::FramePresentedInfo;
using fuchsia::scenic::scheduling::FuturePresentationTimes;
using fuchsia::scenic::scheduling::PresentReceivedInfo;

namespace flutter_runner::testing {
namespace {

std::string GetCurrentTestName() {
  return ::testing::UnitTest::GetInstance()->current_test_info()->name();
}

fml::TimePoint TimePointFromInt(int64_t i) {
  return fml::TimePoint::FromEpochDelta(fml::TimeDelta::FromNanoseconds(i));
}

fml::TimeDelta TimeDeltaFromInt(int64_t i) {
  return fml::TimeDelta::FromNanoseconds(i);
}

int64_t TimePointToInt(fml::TimePoint time) {
  return time.ToEpochDelta().ToNanoseconds();
}

fuchsia::scenic::scheduling::PresentationInfo CreatePresentationInfo(
    zx_time_t latch_point,
    zx_time_t presentation_time) {
  fuchsia::scenic::scheduling::PresentationInfo info;

  info.set_latch_point(latch_point);
  info.set_presentation_time(presentation_time);
  return info;
}

FramePresentedInfo MakeFramePresentedInfoForOnePresent(
    int64_t latched_time,
    int64_t frame_presented_time) {
  std::vector<PresentReceivedInfo> present_infos;
  present_infos.emplace_back();
  present_infos.back().set_present_received_time(0);
  present_infos.back().set_latched_time(0);
  return FramePresentedInfo{
      .actual_presentation_time = 0,
      .presentation_infos = std::move(present_infos),
      .num_presents_allowed = 1,
  };
}

void AwaitVsyncChecked(GfxSessionConnection& session_connection,
                       bool& condition_variable,
                       fml::TimeDelta expected_frame_start,
                       fml::TimeDelta expected_frame_end) {
  session_connection.AwaitVsync(
      [&condition_variable,
       expected_frame_start = std::move(expected_frame_start),
       expected_frame_end = std::move(expected_frame_end)](
          fml::TimePoint frame_start, fml::TimePoint frame_end) {
        EXPECT_EQ(frame_start.ToEpochDelta(), expected_frame_start);
        EXPECT_EQ(frame_end.ToEpochDelta(), expected_frame_end);
        condition_variable = true;
      });
}

};  // namespace

class GfxSessionConnectionTest : public ::testing::Test,
                                 public fuchsia::ui::scenic::SessionListener {
 protected:
  GfxSessionConnectionTest()
      : session_listener_(this), session_subloop_(loop_.StartNewLoop()) {
    auto [session, session_listener] =
        fake_session().Bind(session_subloop_->dispatcher());

    session_ = std::move(session);
    session_listener_.Bind(std::move(session_listener));
  }
  ~GfxSessionConnectionTest() override = default;

  async::TestLoop& loop() { return loop_; }

  FakeSession& fake_session() { return fake_session_; }

  inspect::Node GetInspectNode() {
    return inspector_.GetRoot().CreateChild("GfxSessionConnectionTest");
  }

  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> TakeSessionHandle() {
    FML_CHECK(session_.is_valid());
    return std::move(session_);
  }

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override { FAIL(); }

  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override {
    FAIL();
  }

  async::TestLoop loop_;

  inspect::Inspector inspector_;

  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session_;
  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_;

  std::unique_ptr<async::LoopInterface> session_subloop_;
  FakeSession fake_session_;
};

TEST_F(GfxSessionConnectionTest, Initialization) {
  // Create the GfxSessionConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  const std::string debug_name = GetCurrentTestName();
  flutter_runner::GfxSessionConnection session_connection(
      debug_name, GetInspectNode(), TakeSessionHandle(), []() { FAIL(); },
      [](auto...) { FAIL(); }, 1, fml::TimeDelta::Zero());
  EXPECT_EQ(fake_session().debug_name(), "");
  EXPECT_TRUE(fake_session().command_queue().empty());

  // Simulate an AwaitVsync that comes immediately, before
  // `RequestPresentationTimes` returns.
  bool await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    fml::TimeDelta::Zero(), kDefaultPresentationInterval);
  EXPECT_TRUE(await_vsync_fired);

  // Ensure the debug name is set.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_session().debug_name(), debug_name);
  EXPECT_TRUE(fake_session().command_queue().empty());
}

TEST_F(GfxSessionConnectionTest, SessionDisconnect) {
  // Set up a callback which allows sensing of the session error state.
  bool session_error_fired = false;
  fml::closure on_session_error = [&session_error_fired]() {
    session_error_fired = true;
  };

  // Create the GfxSessionConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::GfxSessionConnection session_connection(
      GetCurrentTestName(), GetInspectNode(), TakeSessionHandle(),
      std::move(on_session_error), [](auto...) { FAIL(); }, 1,
      fml::TimeDelta::Zero());
  EXPECT_FALSE(session_error_fired);

  // Simulate a session disconnection, then Pump the loop.  The session error
  // callback will fire.
  fake_session().DisconnectSession();
  loop().RunUntilIdle();
  EXPECT_TRUE(session_error_fired);
}

TEST_F(GfxSessionConnectionTest, BasicPresent) {
  // Set up callbacks which allow sensing of how many presents
  // (`RequestPresentationTimes` or `Present` calls) were handled.
  size_t request_times_called = 0u;
  size_t presents_called = 0u;
  fake_session().SetRequestPresentationTimesHandler([&request_times_called](
                                                        auto...) -> auto {
    request_times_called++;
    return FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  });
  fake_session().SetPresent2Handler([&presents_called](auto...) -> auto {
    presents_called++;
    return FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  });

  // Set up a callback which allows sensing of how many vsync's
  // (`OnFramePresented` events) were handled.
  size_t vsyncs_handled = 0u;
  on_frame_presented_event on_frame_presented = [&vsyncs_handled](auto...) {
    vsyncs_handled++;
  };

  // Create the GfxSessionConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::GfxSessionConnection session_connection(
      GetCurrentTestName(), GetInspectNode(), TakeSessionHandle(),
      []() { FAIL(); }, std::move(on_frame_presented), 1,
      fml::TimeDelta::Zero());
  EXPECT_TRUE(fake_session().command_queue().empty());
  EXPECT_EQ(request_times_called, 0u);
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Pump the loop; `RequestPresentationTimes`, `Present`, and both of their
  // callbacks are called.
  loop().RunUntilIdle();
  EXPECT_TRUE(fake_session().command_queue().empty());
  EXPECT_EQ(request_times_called, 1u);
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Fire the `OnFramePresented` event associated with the first `Present`, then
  // pump the loop.  The `OnFramePresented` event is resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_TRUE(fake_session().command_queue().empty());
  EXPECT_EQ(request_times_called, 1u);
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Simulate an AwaitVsync that comes after the first `OnFramePresented`
  // event.
  bool await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    fml::TimeDelta::Zero(), kDefaultPresentationInterval);
  EXPECT_TRUE(await_vsync_fired);

  // Call Present and Pump the loop; `Present` and its callback is called.
  await_vsync_fired = false;
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_TRUE(fake_session().command_queue().empty());
  EXPECT_FALSE(await_vsync_fired);
  EXPECT_EQ(request_times_called, 1u);
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Fire the `OnFramePresented` event associated with the second `Present`,
  // then pump the loop.  The `OnFramePresented` event is resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_TRUE(fake_session().command_queue().empty());
  EXPECT_FALSE(await_vsync_fired);
  EXPECT_EQ(request_times_called, 1u);
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 2u);

  // Simulate an AwaitVsync that comes after the second `OnFramePresented`
  // event.
  await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    kDefaultPresentationInterval,
                    kDefaultPresentationInterval * 2);
  EXPECT_TRUE(await_vsync_fired);
}

TEST_F(GfxSessionConnectionTest, AwaitVsyncBackpressure) {
  // Set up a callback which allows sensing of how many presents
  // (`Present` calls) were handled.
  size_t presents_called = 0u;
  fake_session().SetPresent2Handler([&presents_called](auto...) -> auto {
    presents_called++;
    return FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  });

  // Set up a callback which allows sensing of how many vsync's
  // (`OnFramePresented` events) were handled.
  size_t vsyncs_handled = 0u;
  on_frame_presented_event on_frame_presented = [&vsyncs_handled](auto...) {
    vsyncs_handled++;
  };

  // Create the GfxSessionConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::GfxSessionConnection session_connection(
      GetCurrentTestName(), GetInspectNode(), TakeSessionHandle(),
      []() { FAIL(); }, std::move(on_frame_presented), 1,
      fml::TimeDelta::Zero());
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Pump the loop; `RequestPresentationTimes`, `Present`, and both of their
  // callbacks are called.
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Simulate an AwaitVsync that comes before the first `OnFramePresented`
  // event.
  bool await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    fml::TimeDelta::Zero(), kDefaultPresentationInterval);
  EXPECT_FALSE(await_vsync_fired);

  // Fire the `OnFramePresented` event associated with the first `Present`, then
  // pump the loop.  The `OnFramePresented` event is resolved.  The AwaitVsync
  // callback is resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_TRUE(await_vsync_fired);
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Simulate an AwaitVsync that comes before the second `Present`.
  await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    kDefaultPresentationInterval,
                    kDefaultPresentationInterval * 2);
  EXPECT_TRUE(await_vsync_fired);

  // Call Present and Pump the loop; `Present` and its callback is called.
  await_vsync_fired = false;
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_FALSE(await_vsync_fired);
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Simulate an AwaitVsync that comes before the second `OnFramePresented`
  // event.
  await_vsync_fired = false;
  AwaitVsyncChecked(session_connection, await_vsync_fired,
                    kDefaultPresentationInterval * 2,
                    kDefaultPresentationInterval * 3);
  EXPECT_FALSE(await_vsync_fired);

  // Fire the `OnFramePresented` event associated with the second `Present`,
  // then pump the loop.  The `OnFramePresented` event is resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_TRUE(await_vsync_fired);
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 2u);
}

TEST_F(GfxSessionConnectionTest, PresentBackpressure) {
  // Set up a callback which allows sensing of how many presents
  // (`Present` calls) were handled.
  size_t presents_called = 0u;
  fake_session().SetPresent2Handler([&presents_called](auto...) -> auto {
    presents_called++;
    return FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  });

  // Set up a callback which allows sensing of how many vsync's
  // (`OnFramePresented` events) were handled.
  size_t vsyncs_handled = 0u;
  on_frame_presented_event on_frame_presented = [&vsyncs_handled](auto...) {
    vsyncs_handled++;
  };

  // Create the GfxSessionConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::GfxSessionConnection session_connection(
      GetCurrentTestName(), GetInspectNode(), TakeSessionHandle(),
      []() { FAIL(); }, std::move(on_frame_presented), 1,
      fml::TimeDelta::Zero());
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Pump the loop; `RequestPresentationTimes`, `Present`, and both of their
  // callbacks are called.
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Call Present and Pump the loop; `Present` is not called due to backpressue.
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Call Present again and Pump the loop; `Present` is not called due to
  // backpressue.
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Fire the `OnFramePresented` event associated with the first `Present`, then
  // pump the loop.  The `OnFramePresented` event is resolved.  The pending
  // `Present` calls are resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Call Present and Pump the loop; `Present` is not called due to
  // backpressue.
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Call Present again and Pump the loop; `Present` is not called due to
  // backpressue.
  session_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(vsyncs_handled, 1u);

  // Fire the `OnFramePresented` event associated with the second `Present`,
  // then pump the loop.  The `OnFramePresented` event is resolved.  The pending
  // `Present` calls are resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 3u);
  EXPECT_EQ(vsyncs_handled, 2u);

  // Fire the `OnFramePresented` event associated with the third `Present`,
  // then pump the loop.  The `OnFramePresented` event is resolved.  No pending
  // `Present` calls exist, so none are resolved.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 3u);
  EXPECT_EQ(vsyncs_handled, 3u);
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
      GfxSessionConnection::CalculateNextLatchPoint(
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
  const auto next_vsync = flutter_runner::GfxSessionConnection::SnapToNextPhase(
      now, last_presentation_time, delta);

  EXPECT_EQ(now + delta, next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNow) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(9);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync = flutter_runner::GfxSessionConnection::SnapToNextPhase(
      now, last_presentation_time, delta);

  // math here: 10 - 9 = 1
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(1), next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNowMultiJump) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(34);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync = flutter_runner::GfxSessionConnection::SnapToNextPhase(
      now, last_presentation_time, delta);

  // zeroes: -34, -24, -14, -4, 6, ...
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(6), next_vsync);
}

TEST(SnapToNextPhaseTest, SnapAfterNowMultiJumpAccountForCeils) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(20);
  const auto delta = fml::TimeDelta::FromNanoseconds(16);
  const auto next_vsync = flutter_runner::GfxSessionConnection::SnapToNextPhase(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::GetTargetTimes(
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
        flutter_runner::GfxSessionConnection::GetTargetTimes(
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
  // to CPU contention. This test has GfxSessionConnection wake up to
  // schedule 0-4ns after when |now| should be - and we verify that the results
  // should be the same as if there were no delay.
  const fml::TimeDelta vsync_offset = TimeDeltaFromInt(0);
  const fml::TimeDelta vsync_interval = TimeDeltaFromInt(10);

  fml::TimePoint last_targeted_vsync = TimePointFromInt(0);
  fml::TimePoint now = TimePointFromInt(5);
  fml::TimePoint next_vsync = TimePointFromInt(10);

  for (int i = 0; i < 100; ++i) {
    const auto target_times =
        flutter_runner::GfxSessionConnection::GetTargetTimes(
            vsync_offset, vsync_interval, last_targeted_vsync, now, next_vsync);

    const auto target_times_delay =
        flutter_runner::GfxSessionConnection::GetTargetTimes(
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
      flutter_runner::GfxSessionConnection::UpdatePresentationInfo(
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
      flutter_runner::GfxSessionConnection::UpdatePresentationInfo(
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
      flutter_runner::GfxSessionConnection::UpdatePresentationInfo(
          std::move(future_info), new_presentation_info);

  EXPECT_EQ(new_presentation_info.presentation_time(), 30);
}

}  // namespace flutter_runner::testing
