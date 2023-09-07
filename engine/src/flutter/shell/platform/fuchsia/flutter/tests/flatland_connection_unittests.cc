// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/flatland_connection.h"

#include <fuchsia/scenic/scheduling/cpp/fidl.h>
#include <fuchsia/ui/composition/cpp/fidl.h>
#include <lib/async-testing/test_loop.h>
#include <lib/async/cpp/task.h>

#include <string>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

#include "fakes/scenic/fake_flatland.h"

namespace flutter_runner::testing {

namespace {

std::string GetCurrentTestName() {
  return ::testing::UnitTest::GetInstance()->current_test_info()->name();
}

void AwaitVsyncChecked(FlatlandConnection& flatland_connection,
                       bool& condition_variable,
                       fml::TimeDelta expected_frame_delta) {
  flatland_connection.AwaitVsync(
      [&condition_variable,
       expected_frame_delta = std::move(expected_frame_delta)](
          fml::TimePoint frame_start, fml::TimePoint frame_end) {
        EXPECT_EQ(frame_end.ToEpochDelta() - frame_start.ToEpochDelta(),
                  expected_frame_delta);
        condition_variable = true;
      });
}

void AwaitVsyncChecked(FlatlandConnection& flatland_connection,
                       bool& condition_variable,
                       fml::TimePoint expected_frame_end) {
  flatland_connection.AwaitVsync(
      [&condition_variable, expected_frame_end = std::move(expected_frame_end)](
          fml::TimePoint frame_start, fml::TimePoint frame_end) {
        EXPECT_EQ(frame_end, expected_frame_end);
        condition_variable = true;
      });
}

std::vector<fuchsia::scenic::scheduling::PresentationInfo>
CreateFuturePresentationInfos(const fml::TimePoint& presentation_time_1,
                              const fml::TimePoint& presentation_time_2) {
  fuchsia::scenic::scheduling::PresentationInfo info_1;
  info_1.set_presentation_time(
      presentation_time_1.ToEpochDelta().ToNanoseconds());
  std::vector<fuchsia::scenic::scheduling::PresentationInfo> infos;
  infos.push_back(std::move(info_1));
  fuchsia::scenic::scheduling::PresentationInfo info_2;
  info_2.set_presentation_time(
      presentation_time_2.ToEpochDelta().ToNanoseconds());
  infos.push_back(std::move(info_2));
  return infos;
}

}  // namespace

class FlatlandConnectionTest : public ::testing::Test {
 protected:
  FlatlandConnectionTest()
      : session_subloop_(loop_.StartNewLoop()),
        flatland_handle_(
            fake_flatland_.ConnectFlatland(session_subloop_->dispatcher())) {}
  ~FlatlandConnectionTest() override = default;

  async::TestLoop& loop() { return loop_; }

  FakeFlatland& fake_flatland() { return fake_flatland_; }

  fidl::InterfaceHandle<fuchsia::ui::composition::Flatland>
  TakeFlatlandHandle() {
    FML_CHECK(flatland_handle_.is_valid());
    return std::move(flatland_handle_);
  }

  // Syntactic sugar for OnNextFrameBegin
  void OnNextFrameBegin(int num_present_credits,
                        const fml::TimePoint& presentation_time_1,
                        const fml::TimePoint& presentation_time_2) {
    fuchsia::ui::composition::OnNextFrameBeginValues on_next_frame_begin_values;
    on_next_frame_begin_values.set_additional_present_credits(
        num_present_credits);
    on_next_frame_begin_values.set_future_presentation_infos(
        CreateFuturePresentationInfos(presentation_time_1,
                                      presentation_time_2));
    fake_flatland().FireOnNextFrameBeginEvent(
        std::move(on_next_frame_begin_values));
  }
  void OnNextFrameBegin(int num_present_credits) {
    const auto now = fml::TimePoint::Now();
    const auto kPresentationTime1 = now + fml::TimeDelta::FromSeconds(100);
    const auto kPresentationTime2 = now + fml::TimeDelta::FromSeconds(200);
    OnNextFrameBegin(num_present_credits, kPresentationTime1,
                     kPresentationTime2);
  }

 private:
  async::TestLoop loop_;
  std::unique_ptr<async::LoopInterface> session_subloop_;

  FakeFlatland fake_flatland_;

  fidl::InterfaceHandle<fuchsia::ui::composition::Flatland> flatland_handle_;
};

TEST_F(FlatlandConnectionTest, Initialization) {
  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  const std::string debug_name = GetCurrentTestName();
  flutter_runner::FlatlandConnection flatland_connection(
      debug_name, TakeFlatlandHandle(), []() { FAIL(); },
      [](auto...) { FAIL(); });
  EXPECT_EQ(fake_flatland().debug_name(), "");

  // Simulate an AwaitVsync that returns immediately.
  bool await_vsync_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_fired,
                    kInitialFlatlandVsyncOffset);
  EXPECT_TRUE(await_vsync_fired);

  // Ensure the debug name is set.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_flatland().debug_name(), debug_name);
}

TEST_F(FlatlandConnectionTest, FlatlandDisconnect) {
  // Set up a callback which allows sensing of the error state.
  bool error_fired = false;
  fml::closure on_session_error = [&error_fired]() { error_fired = true; };

  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::FlatlandConnection flatland_connection(
      GetCurrentTestName(), TakeFlatlandHandle(), std::move(on_session_error),
      [](auto...) { FAIL(); });
  EXPECT_FALSE(error_fired);

  // Simulate a flatland disconnection, then Pump the loop.  The error callback
  // will fire.
  fake_flatland().Disconnect(
      fuchsia::ui::composition::FlatlandError::BAD_OPERATION);
  loop().RunUntilIdle();
  EXPECT_TRUE(error_fired);
}

TEST_F(FlatlandConnectionTest, BasicPresent) {
  // Set up callbacks which allow sensing of how many presents were handled.
  size_t presents_called = 0u;
  zx_handle_t release_fence_handle;
  fake_flatland().SetPresentHandler([&presents_called,
                                     &release_fence_handle](auto present_args) {
    presents_called++;
    release_fence_handle = present_args.release_fences().empty()
                               ? ZX_HANDLE_INVALID
                               : present_args.release_fences().front().get();
  });

  // Set up a callback which allows sensing of how many vsync's
  // (`OnFramePresented` events) were handled.
  size_t vsyncs_handled = 0u;
  on_frame_presented_event on_frame_presented = [&vsyncs_handled](auto...) {
    vsyncs_handled++;
  };

  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::FlatlandConnection flatland_connection(
      GetCurrentTestName(), TakeFlatlandHandle(), []() { FAIL(); },
      std::move(on_frame_presented));
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Pump the loop. Nothing is called.
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Simulate an AwaitVsync that comes after the first call.
  bool await_vsync_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_fired,
                    kInitialFlatlandVsyncOffset);
  EXPECT_TRUE(await_vsync_fired);

  // Call Present and Pump the loop; `Present` and its callback is called. No
  // release fence should be queued.
  await_vsync_fired = false;
  zx::event first_release_fence;
  zx::event::create(0, &first_release_fence);
  const zx_handle_t first_release_fence_handle = first_release_fence.get();
  flatland_connection.EnqueueReleaseFence(std::move(first_release_fence));
  flatland_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);
  EXPECT_EQ(release_fence_handle, ZX_HANDLE_INVALID);
  EXPECT_EQ(vsyncs_handled, 0u);
  EXPECT_FALSE(await_vsync_fired);

  // Fire the `OnNextFrameBegin` event. AwaitVsync should be fired.
  const auto now = fml::TimePoint::Now();
  const auto kPresentationTime1 = now + fml::TimeDelta::FromSeconds(100);
  const auto kPresentationTime2 = now + fml::TimeDelta::FromSeconds(200);
  fuchsia::ui::composition::OnNextFrameBeginValues on_next_frame_begin_values;
  on_next_frame_begin_values.set_additional_present_credits(3);
  on_next_frame_begin_values.set_future_presentation_infos(
      CreateFuturePresentationInfos(kPresentationTime1, kPresentationTime2));
  fake_flatland().FireOnNextFrameBeginEvent(
      std::move(on_next_frame_begin_values));
  loop().RunUntilIdle();
  AwaitVsyncChecked(flatland_connection, await_vsync_fired, kPresentationTime1);
  EXPECT_TRUE(await_vsync_fired);

  // Fire the `OnFramePresented` event associated with the first `Present`,
  fake_flatland().FireOnFramePresentedEvent(
      fuchsia::scenic::scheduling::FramePresentedInfo());
  loop().RunUntilIdle();
  EXPECT_EQ(vsyncs_handled, 1u);

  // Call Present for a second time and Pump the loop; `Present` and its
  // callback is called. Release fences for the earlier present is used.
  await_vsync_fired = false;
  flatland_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 2u);
  EXPECT_EQ(release_fence_handle, first_release_fence_handle);

  // AwaitVsync should be fired with the second present.
  await_vsync_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_fired, kPresentationTime2);
  EXPECT_TRUE(await_vsync_fired);
}

TEST_F(FlatlandConnectionTest, AwaitVsyncsBeforeOnNextFrameBegin) {
  // Set up callbacks which allow sensing of how many presents were handled.
  size_t presents_called = 0u;
  fake_flatland().SetPresentHandler(
      [&presents_called](auto present_args) { presents_called++; });

  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::FlatlandConnection flatland_connection(
      GetCurrentTestName(), TakeFlatlandHandle(), []() { FAIL(); },
      [](auto...) {});
  EXPECT_EQ(presents_called, 0u);

  // Pump the loop. Nothing is called.
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 0u);

  // Simulate an AwaitVsync that comes before the first Present.
  bool await_vsync_callback_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_callback_fired,
                    kInitialFlatlandVsyncOffset);
  EXPECT_TRUE(await_vsync_callback_fired);

  // AwaitVsync that comes before the first Present.
  bool await_vsync_secondary_callback_fired = false;
  flatland_connection.AwaitVsyncForSecondaryCallback(
      [&await_vsync_secondary_callback_fired](fml::TimePoint frame_start,
                                              fml::TimePoint frame_end) {
        await_vsync_secondary_callback_fired = true;
      });
  EXPECT_TRUE(await_vsync_secondary_callback_fired);
}

TEST_F(FlatlandConnectionTest, RunsOutOfFuturePresentationInfos) {
  // Set up callbacks which allow sensing of how many presents were handled.
  size_t presents_called = 0u;
  fake_flatland().SetPresentHandler(
      [&presents_called](auto present_args) { presents_called++; });

  // Set up a callback which allows sensing of how many vsync's
  // (`OnFramePresented` events) were handled.
  size_t vsyncs_handled = 0u;
  on_frame_presented_event on_frame_presented = [&vsyncs_handled](auto...) {
    vsyncs_handled++;
  };

  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  flutter_runner::FlatlandConnection flatland_connection(
      GetCurrentTestName(), TakeFlatlandHandle(), []() { FAIL(); },
      std::move(on_frame_presented));
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Pump the loop. Nothing is called.
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 0u);
  EXPECT_EQ(vsyncs_handled, 0u);

  // Simulate an AwaitVsync that comes before the first Present.
  bool await_vsync_callback_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_callback_fired,
                    kInitialFlatlandVsyncOffset);
  EXPECT_TRUE(await_vsync_callback_fired);

  // Queue Present.
  flatland_connection.Present();
  loop().RunUntilIdle();
  EXPECT_EQ(presents_called, 1u);

  // Fire the `OnNextFrameBegin` event. AwaitVsync callback should be fired with
  // the first presentation time.
  await_vsync_callback_fired = false;
  const auto kPresentationTime1 =
      fml::TimePoint::Now() + fml::TimeDelta::FromSeconds(123);
  const auto kVsyncInterval = fml::TimeDelta::FromSeconds(234);
  const auto kPresentationTime2 = kPresentationTime1 + kVsyncInterval;
  OnNextFrameBegin(1, kPresentationTime1, kPresentationTime2);
  loop().RunUntilIdle();
  AwaitVsyncChecked(flatland_connection, await_vsync_callback_fired,
                    kPresentationTime1);
  EXPECT_TRUE(await_vsync_callback_fired);

  // Second consecutive AwaitVsync callback should be fired with
  // the second presentation time.
  await_vsync_callback_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_callback_fired,
                    kPresentationTime2);
  EXPECT_TRUE(await_vsync_callback_fired);

  // Another AwaitVsync callback should be fired with vsync_interval.
  await_vsync_callback_fired = false;
  AwaitVsyncChecked(flatland_connection, await_vsync_callback_fired,
                    kPresentationTime2 + kVsyncInterval);
  EXPECT_TRUE(await_vsync_callback_fired);
}

TEST_F(FlatlandConnectionTest, PresentCreditExhaustion) {
  // Set up callbacks which allow sensing of how many presents were handled.
  size_t num_presents_called = 0u;
  size_t num_release_fences = 0u;
  size_t num_acquire_fences = 0u;

  auto reset_test_counters = [&num_presents_called, &num_acquire_fences,
                              &num_release_fences]() {
    num_presents_called = 0u;
    num_release_fences = 0u;
    num_acquire_fences = 0u;
  };

  fake_flatland().SetPresentHandler(
      [&num_presents_called, &num_acquire_fences, &num_release_fences](
          fuchsia::ui::composition::PresentArgs present_args) {
        num_presents_called++;
        num_acquire_fences = present_args.acquire_fences().size();
        num_release_fences = present_args.release_fences().size();
      });

  // Create the FlatlandConnection but don't pump the loop.  No FIDL calls are
  // completed yet.
  on_frame_presented_event on_frame_presented = [](auto...) {};
  flutter_runner::FlatlandConnection flatland_connection(
      GetCurrentTestName(), TakeFlatlandHandle(), []() { FAIL(); },
      std::move(on_frame_presented));
  EXPECT_EQ(num_presents_called, 0u);

  // Pump the loop. Nothing is called.
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 0u);

  // Simulate an AwaitVsync that comes before the first Present.
  flatland_connection.AwaitVsync([](fml::TimePoint, fml::TimePoint) {});
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 0u);

  // This test uses a fire callback that triggers Present() with a single
  // acquire and release fence in order to approximate the behavior of the real
  // flutter fire callback and let us drive presents with ONFBs
  auto fire_callback = [dispatcher = loop().dispatcher(), &flatland_connection](
                           fml::TimePoint frame_start,
                           fml::TimePoint frame_end) {
    async::PostTask(dispatcher, [&flatland_connection]() {
      zx::event acquire_fence;
      zx::event::create(0, &acquire_fence);
      zx::event release_fence;
      zx::event::create(0, &release_fence);
      flatland_connection.EnqueueAcquireFence(std::move(acquire_fence));
      flatland_connection.EnqueueReleaseFence(std::move(release_fence));
      flatland_connection.Present();
    });
  };

  // Call Await Vsync with a callback that triggers Present and consumes the one
  // and only present credit we start with.
  reset_test_counters();
  flatland_connection.AwaitVsync(fire_callback);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 1u);
  EXPECT_EQ(num_acquire_fences, 1u);
  EXPECT_EQ(num_release_fences, 0u);

  // Do it again, but this time we should not get a present because the client
  // has exhausted its present credits.
  reset_test_counters();
  flatland_connection.AwaitVsync(fire_callback);
  OnNextFrameBegin(0);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 0u);

  // Supply a present credit but dont set a new fire callback. Fire callback
  // from previous ONFB should fire and trigger a Present()
  reset_test_counters();
  OnNextFrameBegin(1);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 1u);
  EXPECT_EQ(num_acquire_fences, 1u);
  EXPECT_EQ(num_release_fences, 1u);

  // From here on we are testing handling of a race condition where a fire
  // callback is fired but another ONFB arrives before the present from the
  // first fire callback comes in, causing present_credits to be negative
  // within Present().

  uint num_onfb = 5;
  uint num_deferred_callbacks = 0;
  // This callback will accumulate num_onfb+1 calls before firing all
  // of their presents at once.
  auto accumulating_fire_callback = [&](fml::TimePoint frame_start,
                                        fml::TimePoint frame_end) {
    num_deferred_callbacks++;
    if (num_deferred_callbacks > num_onfb) {
      fml::TimePoint now = fml::TimePoint::Now();
      for (uint i = 0; i < num_onfb + 1; i++) {
        fire_callback(now, now);
        num_deferred_callbacks--;
      }
    }
  };

  reset_test_counters();
  for (uint i = 0; i < num_onfb; i++) {
    flatland_connection.AwaitVsync(accumulating_fire_callback);
    // only supply a present credit on the first call. Since Presents are being
    // deferred this credit will not be used up, but we need a credit to call
    // the accumulating_fire_callback
    OnNextFrameBegin(i == 0 ? 1 : 0);
    loop().RunUntilIdle();
    EXPECT_EQ(num_presents_called, 0u);
  }

  // This is the num_onfb+1 call to accumulating_fire_callback which triggers
  // all of the "racing" presents to fire. the first one should be fired,
  // but the other num_onfb Presents should be deferred.
  flatland_connection.AwaitVsync(accumulating_fire_callback);
  OnNextFrameBegin(0);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 1u);
  EXPECT_EQ(num_acquire_fences, 1u);
  EXPECT_EQ(num_release_fences, 1u);

  // Supply a present credit, but pass an empty lambda to AwaitVsync so
  // that it doesnt call Present(). Should get a deferred present with
  // all the accumulate acuire fences
  reset_test_counters();
  flatland_connection.AwaitVsync([](fml::TimePoint, fml::TimePoint) {});
  OnNextFrameBegin(1);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 1u);
  EXPECT_EQ(num_acquire_fences, num_onfb);
  EXPECT_EQ(num_release_fences, 1u);

  // Pump another frame to check that release fences accumulate as expected
  reset_test_counters();
  flatland_connection.AwaitVsync(fire_callback);
  OnNextFrameBegin(1);
  loop().RunUntilIdle();
  EXPECT_EQ(num_presents_called, 1u);
  EXPECT_EQ(num_acquire_fences, 1u);
  EXPECT_EQ(num_release_fences, num_onfb);
}

}  // namespace flutter_runner::testing
