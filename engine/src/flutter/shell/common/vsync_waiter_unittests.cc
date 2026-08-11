// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#define FML_USED_ON_EMBEDDER

#include <initializer_list>
#include <string>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/shell/common/switches.h"

#include "gtest/gtest.h"
#include "thread_host.h"
#include "vsync_waiter.h"

namespace flutter {
namespace testing {

class TestVsyncWaiter : public VsyncWaiter {
 public:
  explicit TestVsyncWaiter(const TaskRunners& task_runners)
      : VsyncWaiter(task_runners) {}

  int await_vsync_call_count_ = 0;

  void SimulateVsync() {
    const fml::TimePoint frame_start_time = fml::TimePoint::Now();
    FireCallback(frame_start_time,
                 frame_start_time + fml::TimeDelta::FromMilliseconds(16),
                 false);
  }

 protected:
  void AwaitVSync() override { await_vsync_call_count_++; }
};

TEST(VsyncWaiterTest, NoUnneededAwaitVsync) {
  using flutter::ThreadHost;
  std::string prefix = "vsync_waiter_test";

  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();

  const flutter::TaskRunners task_runners(prefix, task_runner, task_runner,
                                          task_runner, task_runner);

  auto vsync_waiter = std::make_shared<TestVsyncWaiter>(task_runners);

  vsync_waiter->ScheduleSecondaryCallback(1, [] {});
  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);

  vsync_waiter->ScheduleSecondaryCallback(2, [] {});
  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);
}

TEST(VsyncWaiterTest, PreFrameCallbackRunsBeforePrimaryAndSecondaryCallbacks) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  const flutter::TaskRunners task_runners("vsync_waiter_callback_order_test",
                                          task_runner, task_runner, task_runner,
                                          task_runner);
  auto vsync_waiter = std::make_shared<TestVsyncWaiter>(task_runners);
  std::vector<std::string> callback_order;

  vsync_waiter->SchedulePreFrameCallback(
      1, [&callback_order] { callback_order.push_back("pre-frame"); });
  vsync_waiter->AsyncWaitForVsync(
      [&callback_order](auto) { callback_order.push_back("primary"); });
  vsync_waiter->ScheduleSecondaryCallback(
      2, [&callback_order] { callback_order.push_back("secondary"); });

  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);
  vsync_waiter->SimulateVsync();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();

  EXPECT_EQ(callback_order,
            (std::vector<std::string>{"pre-frame", "primary", "secondary"}));
}

TEST(VsyncWaiterTest, PrimaryScheduledByPreFrameCallbackJoinsCurrentVsync) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  const flutter::TaskRunners task_runners("vsync_waiter_late_primary_test",
                                          task_runner, task_runner, task_runner,
                                          task_runner);
  auto vsync_waiter = std::make_shared<TestVsyncWaiter>(task_runners);
  std::vector<std::string> callback_order;

  vsync_waiter->SchedulePreFrameCallback(1, [&] {
    callback_order.push_back("pre-frame");
    EXPECT_TRUE(vsync_waiter->CanRegisterCallbackForCurrentVsync());
    vsync_waiter->AsyncWaitForVsync(
        [&](auto) { callback_order.push_back("primary"); });
  });
  vsync_waiter->ScheduleSecondaryCallback(
      2, [&] { callback_order.push_back("secondary"); });

  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);
  vsync_waiter->SimulateVsync();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();

  EXPECT_EQ(callback_order,
            (std::vector<std::string>{"pre-frame", "primary", "secondary"}));
  EXPECT_FALSE(vsync_waiter->CanRegisterCallbackForCurrentVsync());
  // The primary callback joined the already-fired vsync rather than arming a
  // second one.
  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);
}

TEST(VsyncWaiterTest, PreFrameCallbackScheduledAfterFireTargetsNextVsync) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  const flutter::TaskRunners task_runners("vsync_waiter_next_vsync_test",
                                          task_runner, task_runner, task_runner,
                                          task_runner);
  auto vsync_waiter = std::make_shared<TestVsyncWaiter>(task_runners);
  std::vector<std::string> callback_order;

  vsync_waiter->SchedulePreFrameCallback(
      1, [&] { callback_order.push_back("current pre-frame"); });
  vsync_waiter->AsyncWaitForVsync(
      [&](auto) { callback_order.push_back("current primary"); });
  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 1);

  vsync_waiter->SimulateVsync();
  EXPECT_TRUE(vsync_waiter->CanRegisterCallbackForCurrentVsync());

  // This callback was registered after the platform vsync fired, so it must
  // arm and wait for the next vsync instead of joining the current one.
  vsync_waiter->SchedulePreFrameCallback(
      2, [&] { callback_order.push_back("next pre-frame"); });
  EXPECT_EQ(vsync_waiter->await_vsync_call_count_, 2);

  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  EXPECT_EQ(callback_order,
            (std::vector<std::string>{"current pre-frame", "current primary"}));

  vsync_waiter->SimulateVsync();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  EXPECT_EQ(callback_order,
            (std::vector<std::string>{"current pre-frame", "current primary",
                                      "next pre-frame"}));
}

}  // namespace testing
}  // namespace flutter
