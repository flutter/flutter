// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>

#include <gtest/gtest.h>
#include <lib/async-loop/default.h>
#include <lib/zx/event.h>
#include <zircon/syscalls.h>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "flutter/shell/platform/fuchsia/flutter/task_runner_adapter.h"
#include "flutter/shell/platform/fuchsia/flutter/thread.h"
#include "flutter/shell/platform/fuchsia/flutter/vsync_waiter.h"

namespace flutter_runner_test {

class VsyncWaiterTest : public testing::Test {
 public:
  VsyncWaiterTest() {}

  ~VsyncWaiterTest() = default;

  std::unique_ptr<flutter::VsyncWaiter> CreateVsyncWaiter(
      flutter::TaskRunners task_runners) {
    return std::make_unique<flutter_runner::VsyncWaiter>(
        "VsyncWaiterTest", vsync_event_.get(), task_runners);
  }

  void SignalVsyncEvent() {
    auto status =
        zx_object_signal(vsync_event_.get(), 0,
                         flutter_runner::VsyncWaiter::SessionPresentSignal);
    EXPECT_EQ(status, ZX_OK);
  }

 protected:
  void SetUp() override {
    auto status = zx::event::create(0, &vsync_event_);
    EXPECT_EQ(status, ZX_OK);
  }

 private:
  zx::event vsync_event_;
};

TEST_F(VsyncWaiterTest, AwaitVsync) {
  std::array<std::unique_ptr<flutter_runner::Thread>, 3> threads;

  for (auto& thread : threads) {
    thread.reset(new flutter_runner::Thread());
  }

  async::Loop loop(&kAsyncLoopConfigAttachToCurrentThread);

  const flutter::TaskRunners task_runners(
      "VsyncWaiterTests",  // Dart thread labels
      flutter_runner::CreateFMLTaskRunner(
          async_get_default_dispatcher()),  // platform
      flutter_runner::CreateFMLTaskRunner(threads[0]->dispatcher()),  // raster
      flutter_runner::CreateFMLTaskRunner(threads[1]->dispatcher()),  // ui
      flutter_runner::CreateFMLTaskRunner(threads[2]->dispatcher())   // io
  );

  auto vsync_waiter = CreateVsyncWaiter(std::move(task_runners));

  fml::AutoResetWaitableEvent latch;
  vsync_waiter->AsyncWaitForVsync(
      [&latch](fml::TimePoint frame_start_time,
               fml::TimePoint frame_target_time) { latch.Signal(); });
  SignalVsyncEvent();

  bool did_timeout =
      latch.WaitWithTimeout(fml::TimeDelta::FromMilliseconds(5000));

  // False indicates we were signalled rather than timed out
  EXPECT_FALSE(did_timeout);

  vsync_waiter.reset();
  for (const auto& thread : threads) {
    thread->Quit();
  }
}

TEST_F(VsyncWaiterTest, SnapToNextPhaseOverlapsWithNow) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(10);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync = flutter_runner::VsyncWaiter::SnapToNextPhase(
      now, last_presentation_time, delta);

  EXPECT_EQ(now + delta, next_vsync);
}

TEST_F(VsyncWaiterTest, SnapToNextPhaseAfterNow) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(9);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync = flutter_runner::VsyncWaiter::SnapToNextPhase(
      now, last_presentation_time, delta);

  // math here: 10 - 9 = 1
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(1), next_vsync);
}

TEST_F(VsyncWaiterTest, SnapToNextPhaseAfterNowMultiJump) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(34);
  const auto delta = fml::TimeDelta::FromNanoseconds(10);
  const auto next_vsync = flutter_runner::VsyncWaiter::SnapToNextPhase(
      now, last_presentation_time, delta);

  // zeroes: -34, -24, -14, -4, 6, ...
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(6), next_vsync);
}

TEST_F(VsyncWaiterTest, SnapToNextPhaseAfterNowMultiJumpAccountForCeils) {
  const auto now = fml::TimePoint::Now();
  const auto last_presentation_time = now - fml::TimeDelta::FromNanoseconds(20);
  const auto delta = fml::TimeDelta::FromNanoseconds(16);
  const auto next_vsync = flutter_runner::VsyncWaiter::SnapToNextPhase(
      now, last_presentation_time, delta);

  // zeroes: -20, -4, 12, 28, ...
  EXPECT_EQ(now + fml::TimeDelta::FromNanoseconds(12), next_vsync);
}

}  // namespace flutter_runner_test
