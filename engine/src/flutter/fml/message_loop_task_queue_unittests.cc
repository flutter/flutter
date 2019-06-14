// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queue.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"

class TestWakeable : public fml::Wakeable {
 public:
  using WakeUpCall = std::function<void(const fml::TimePoint)>;

  TestWakeable(WakeUpCall call) : wake_up_call_(call) {}

  void WakeUp(fml::TimePoint time_point) override { wake_up_call_(time_point); }

 private:
  WakeUpCall wake_up_call_;
};

TEST(MessageLoopTaskQueue, StartsWithNoPendingTasks) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  ASSERT_FALSE(task_queue->HasPendingTasks());
}

TEST(MessageLoopTaskQueue, RegisterOneTask) {
  const auto time = fml::TimePoint::Max();

  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  task_queue->SetWakeable(new TestWakeable(
      [&time](fml::TimePoint wake_time) { ASSERT_TRUE(wake_time == time); }));

  task_queue->RegisterTask([] {}, time);
  ASSERT_TRUE(task_queue->HasPendingTasks());
  ASSERT_TRUE(task_queue->GetNumPendingTasks() == 1);
}

TEST(MessageLoopTaskQueue, RegisterTwoTasksAndCount) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  task_queue->RegisterTask([] {}, fml::TimePoint::Now());
  task_queue->RegisterTask([] {}, fml::TimePoint::Max());
  ASSERT_TRUE(task_queue->HasPendingTasks());
  ASSERT_TRUE(task_queue->GetNumPendingTasks() == 2);
}

TEST(MessageLoopTaskQueue, PreserveTaskOrdering) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  int test_val = 0;

  // order: 0
  task_queue->RegisterTask([&test_val]() { test_val = 1; },
                           fml::TimePoint::Now());

  // order: 1
  task_queue->RegisterTask([&test_val]() { test_val = 2; },
                           fml::TimePoint::Now());

  std::vector<fml::closure> invocations;
  task_queue->GetTasksToRunNow(fml::FlushType::kAll, invocations);

  int expected_value = 1;

  for (auto& invocation : invocations) {
    invocation();
    ASSERT_TRUE(test_val == expected_value);
    expected_value++;
  }
}

TEST(MessageLoopTaskQueue, AddRemoveNotifyObservers) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();

  int test_val = 0;
  intptr_t key = 123;

  task_queue->AddTaskObserver(key, [&test_val]() { test_val = 1; });
  task_queue->NotifyObservers();
  ASSERT_TRUE(test_val == 1);

  test_val = 0;
  task_queue->RemoveTaskObserver(key);
  task_queue->NotifyObservers();
  ASSERT_TRUE(test_val == 0);
}

TEST(MessageLoopTaskQueue, WakeUpIndependentOfTime) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();

  int num_wakes = 0;
  task_queue->SetWakeable(new TestWakeable(
      [&num_wakes](fml::TimePoint wake_time) { ++num_wakes; }));

  task_queue->RegisterTask([]() {}, fml::TimePoint::Now());
  task_queue->RegisterTask([]() {}, fml::TimePoint::Max());

  ASSERT_TRUE(num_wakes == 2);
}

TEST(MessageLoopTaskQueue, WakeUpWithMaxIfNoInvocations) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  fml::AutoResetWaitableEvent ev;

  task_queue->SetWakeable(new TestWakeable([&ev](fml::TimePoint wake_time) {
    ASSERT_TRUE(wake_time == fml::TimePoint::Max());
    ev.Signal();
  }));

  std::vector<fml::closure> invocations;
  task_queue->GetTasksToRunNow(fml::FlushType::kAll, invocations);
  ev.Wait();
}

TEST(MessageLoopTaskQueue, WokenUpWithNewerTime) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  fml::CountDownLatch latch(2);

  fml::TimePoint expected = fml::TimePoint::Max();

  task_queue->SetWakeable(
      new TestWakeable([&latch, &expected](fml::TimePoint wake_time) {
        ASSERT_TRUE(wake_time == expected);
        latch.CountDown();
      }));

  task_queue->RegisterTask([]() {}, fml::TimePoint::Max());

  const auto now = fml::TimePoint::Now();
  expected = now;
  task_queue->RegisterTask([]() {}, now);

  latch.Wait();
}
