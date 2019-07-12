// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"
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
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  ASSERT_FALSE(task_queue->HasPendingTasks(queue_id));
}

TEST(MessageLoopTaskQueue, RegisterOneTask) {
  const auto time = fml::TimePoint::Max();

  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  task_queue->SetWakeable(queue_id,
                          new TestWakeable([&time](fml::TimePoint wake_time) {
                            ASSERT_TRUE(wake_time == time);
                          }));

  task_queue->RegisterTask(
      queue_id, [] {}, time);
  ASSERT_TRUE(task_queue->HasPendingTasks(queue_id));
  ASSERT_TRUE(task_queue->GetNumPendingTasks(queue_id) == 1);
}

TEST(MessageLoopTaskQueue, RegisterTwoTasksAndCount) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  task_queue->RegisterTask(
      queue_id, [] {}, fml::TimePoint::Now());
  task_queue->RegisterTask(
      queue_id, [] {}, fml::TimePoint::Max());
  ASSERT_TRUE(task_queue->HasPendingTasks(queue_id));
  ASSERT_TRUE(task_queue->GetNumPendingTasks(queue_id) == 2);
}

TEST(MessageLoopTaskQueue, PreserveTaskOrdering) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  int test_val = 0;

  // order: 0
  task_queue->RegisterTask(
      queue_id, [&test_val]() { test_val = 1; }, fml::TimePoint::Now());

  // order: 1
  task_queue->RegisterTask(
      queue_id, [&test_val]() { test_val = 2; }, fml::TimePoint::Now());

  std::vector<fml::closure> invocations;
  task_queue->GetTasksToRunNow(queue_id, fml::FlushType::kAll, invocations);

  int expected_value = 1;

  for (auto& invocation : invocations) {
    invocation();
    ASSERT_TRUE(test_val == expected_value);
    expected_value++;
  }
}

TEST(MessageLoopTaskQueue, AddRemoveNotifyObservers) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();

  int test_val = 0;
  intptr_t key = 123;

  task_queue->AddTaskObserver(queue_id, key, [&test_val]() { test_val = 1; });
  task_queue->NotifyObservers(queue_id);
  ASSERT_TRUE(test_val == 1);

  test_val = 0;
  task_queue->RemoveTaskObserver(queue_id, key);
  task_queue->NotifyObservers(queue_id);
  ASSERT_TRUE(test_val == 0);
}

TEST(MessageLoopTaskQueue, WakeUpIndependentOfTime) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();

  int num_wakes = 0;
  task_queue->SetWakeable(
      queue_id, new TestWakeable(
                    [&num_wakes](fml::TimePoint wake_time) { ++num_wakes; }));

  task_queue->RegisterTask(
      queue_id, []() {}, fml::TimePoint::Now());
  task_queue->RegisterTask(
      queue_id, []() {}, fml::TimePoint::Max());

  ASSERT_TRUE(num_wakes == 2);
}

TEST(MessageLoopTaskQueue, WokenUpWithNewerTime) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  fml::CountDownLatch latch(2);

  fml::TimePoint expected = fml::TimePoint::Max();

  task_queue->SetWakeable(
      queue_id, new TestWakeable([&latch, &expected](fml::TimePoint wake_time) {
        ASSERT_TRUE(wake_time == expected);
        latch.CountDown();
      }));

  task_queue->RegisterTask(
      queue_id, []() {}, fml::TimePoint::Max());

  const auto now = fml::TimePoint::Now();
  expected = now;
  task_queue->RegisterTask(
      queue_id, []() {}, now);

  latch.Wait();
}
