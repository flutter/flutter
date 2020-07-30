// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <thread>

#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"

class TestWakeable : public fml::Wakeable {
 public:
  using WakeUpCall = std::function<void(const fml::TimePoint)>;

  explicit TestWakeable(WakeUpCall call) : wake_up_call_(call) {}

  void WakeUp(fml::TimePoint time_point) override { wake_up_call_(time_point); }

 private:
  WakeUpCall wake_up_call_;
};

TEST(MessageLoopTaskQueueMergeUnmerge,
     AfterMergePrimaryTasksServicedOnPrimary) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());
  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_1));

  task_queue->Merge(queue_id_1, queue_id_2);
  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());

  ASSERT_EQ(2u, task_queue->GetNumPendingTasks(queue_id_1));
  ASSERT_EQ(0u, task_queue->GetNumPendingTasks(queue_id_2));
}

TEST(MessageLoopTaskQueueMergeUnmerge,
     AfterMergeSecondaryTasksAlsoServicedOnPrimary) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  task_queue->RegisterTask(
      queue_id_2, []() {}, fml::TimePoint::Now());
  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_2));

  task_queue->Merge(queue_id_1, queue_id_2);
  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_1));
  ASSERT_EQ(0u, task_queue->GetNumPendingTasks(queue_id_2));
}

TEST(MessageLoopTaskQueueMergeUnmerge, MergeUnmergeTasksPreserved) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());
  task_queue->RegisterTask(
      queue_id_2, []() {}, fml::TimePoint::Now());

  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_1));
  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_2));

  task_queue->Merge(queue_id_1, queue_id_2);

  ASSERT_EQ(2u, task_queue->GetNumPendingTasks(queue_id_1));
  ASSERT_EQ(0u, task_queue->GetNumPendingTasks(queue_id_2));

  task_queue->Unmerge(queue_id_1);

  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_1));
  ASSERT_EQ(1u, task_queue->GetNumPendingTasks(queue_id_2));
}

TEST(MessageLoopTaskQueueMergeUnmerge, MergeFailIfAlreadyMergedOrSubsumed) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();
  auto queue_id_3 = task_queue->CreateTaskQueue();

  task_queue->Merge(queue_id_1, queue_id_2);

  ASSERT_FALSE(task_queue->Merge(queue_id_1, queue_id_3));
  ASSERT_FALSE(task_queue->Merge(queue_id_2, queue_id_3));
}

TEST(MessageLoopTaskQueueMergeUnmerge, UnmergeFailsOnSubsumed) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  task_queue->Merge(queue_id_1, queue_id_2);

  ASSERT_FALSE(task_queue->Unmerge(queue_id_2));
}

TEST(MessageLoopTaskQueueMergeUnmerge, MergeInvokesBothWakeables) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  fml::CountDownLatch latch(2);

  task_queue->SetWakeable(
      queue_id_1,
      new TestWakeable([&](fml::TimePoint wake_time) { latch.CountDown(); }));
  task_queue->SetWakeable(
      queue_id_2,
      new TestWakeable([&](fml::TimePoint wake_time) { latch.CountDown(); }));

  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());

  task_queue->Merge(queue_id_1, queue_id_2);

  std::vector<fml::closure> invocations;
  task_queue->GetTasksToRunNow(queue_id_1, fml::FlushType::kAll, invocations);

  latch.Wait();
}

TEST(MessageLoopTaskQueueMergeUnmerge,
     MergeUnmergeInvokesBothWakeablesSeparately) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  fml::AutoResetWaitableEvent latch_1, latch_2;

  task_queue->SetWakeable(
      queue_id_1,
      new TestWakeable([&](fml::TimePoint wake_time) { latch_1.Signal(); }));
  task_queue->SetWakeable(
      queue_id_2,
      new TestWakeable([&](fml::TimePoint wake_time) { latch_2.Signal(); }));

  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());
  task_queue->RegisterTask(
      queue_id_2, []() {}, fml::TimePoint::Now());

  task_queue->Merge(queue_id_1, queue_id_2);
  task_queue->Unmerge(queue_id_1);

  std::vector<fml::closure> invocations;

  task_queue->GetTasksToRunNow(queue_id_1, fml::FlushType::kAll, invocations);
  latch_1.Wait();

  task_queue->GetTasksToRunNow(queue_id_2, fml::FlushType::kAll, invocations);
  latch_2.Wait();
}

TEST(MessageLoopTaskQueueMergeUnmerge, GetTasksToRunNowBlocksMerge) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();

  auto queue_id_1 = task_queue->CreateTaskQueue();
  auto queue_id_2 = task_queue->CreateTaskQueue();

  fml::AutoResetWaitableEvent wake_up_start, wake_up_end, merge_start,
      merge_end;

  task_queue->RegisterTask(
      queue_id_1, []() {}, fml::TimePoint::Now());
  task_queue->SetWakeable(queue_id_1,
                          new TestWakeable([&](fml::TimePoint wake_time) {
                            wake_up_start.Signal();
                            wake_up_end.Wait();
                          }));

  std::thread tasks_to_run_now_thread([&]() {
    std::vector<fml::closure> invocations;
    task_queue->GetTasksToRunNow(queue_id_1, fml::FlushType::kAll, invocations);
  });

  wake_up_start.Wait();
  bool merge_done = false;

  std::thread merge_thread([&]() {
    merge_start.Signal();
    task_queue->Merge(queue_id_1, queue_id_2);
    merge_done = true;
    merge_end.Signal();
  });

  merge_start.Wait();
  ASSERT_FALSE(merge_done);
  wake_up_end.Signal();

  merge_end.Wait();
  ASSERT_TRUE(merge_done);

  tasks_to_run_now_thread.join();
  merge_thread.join();
}
