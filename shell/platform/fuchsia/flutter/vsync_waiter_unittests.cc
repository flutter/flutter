// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>

#include <gtest/gtest.h>
#include <lib/zx/event.h>
#include <zircon/syscalls.h>

#include "flutter/fml/synchronization/waitable_event.h"
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

  async::Loop loop(&kAsyncLoopConfigAttachToThread);

  const flutter::TaskRunners task_runners(
      "VsyncWaiterTests",  // Dart thread labels
      flutter_runner::CreateFMLTaskRunner(
          async_get_default_dispatcher()),  // platform
      flutter_runner::CreateFMLTaskRunner(threads[0]->dispatcher()),  // gpu
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

}  // namespace flutter_runner_test
