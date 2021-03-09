// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"

#include <thread>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "gtest/gtest.h"

namespace fml {
namespace testing {

class TestWakeable : public fml::Wakeable {
 public:
  using WakeUpCall = std::function<void(const fml::TimePoint)>;

  explicit TestWakeable(WakeUpCall call) : wake_up_call_(call) {}

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

  const auto now = fml::TimePoint::Now();
  int expected_value = 1;
  for (;;) {
    fml::closure invocation = task_queue->GetNextTaskToRun(queue_id, now);
    if (!invocation) {
      break;
    }
    invocation();
    ASSERT_TRUE(test_val == expected_value);
    expected_value++;
  }
}

void TestNotifyObservers(fml::TaskQueueId queue_id) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  std::vector<fml::closure> observers =
      task_queue->GetObserversToNotify(queue_id);
  for (const auto& observer : observers) {
    observer();
  }
}

TEST(MessageLoopTaskQueue, AddRemoveNotifyObservers) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();

  int test_val = 0;
  intptr_t key = 123;

  task_queue->AddTaskObserver(queue_id, key, [&test_val]() { test_val = 1; });
  TestNotifyObservers(queue_id);
  ASSERT_TRUE(test_val == 1);

  test_val = 0;
  task_queue->RemoveTaskObserver(queue_id, key);
  TestNotifyObservers(queue_id);
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

TEST(MessageLoopTaskQueue, NotifyObserversWhileCreatingQueues) {
  auto task_queues = fml::MessageLoopTaskQueues::GetInstance();
  fml::TaskQueueId queue_id = task_queues->CreateTaskQueue();
  fml::AutoResetWaitableEvent first_observer_executing, before_second_observer;

  task_queues->AddTaskObserver(queue_id, queue_id + 1, [&]() {
    first_observer_executing.Signal();
    before_second_observer.Wait();
  });

  for (int i = 0; i < 100; i++) {
    task_queues->AddTaskObserver(queue_id, queue_id + i + 2, [] {});
  }

  std::thread notify_observers([&]() { TestNotifyObservers(queue_id); });

  first_observer_executing.Wait();

  for (int i = 0; i < 100; i++) {
    task_queues->CreateTaskQueue();
  }

  before_second_observer.Signal();
  notify_observers.join();
}

TEST(MessageLoopTaskQueue, QueueDoNotOwnItself) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto queue_id = task_queue->CreateTaskQueue();
  ASSERT_FALSE(task_queue->Owns(queue_id, queue_id));
}

// TODO(chunhtai): This unit-test is flaky and sometimes fails asynchronizely
// after the test has finished.
// https://github.com/flutter/flutter/issues/43858
TEST(MessageLoopTaskQueue, DISABLED_ConcurrentQueueAndTaskCreatingCounts) {
  auto task_queues = fml::MessageLoopTaskQueues::GetInstance();
  const int base_queue_id = task_queues->CreateTaskQueue();

  const int num_queues = 100;
  std::atomic_bool created[num_queues * 3];
  std::atomic_int num_tasks[num_queues * 3];
  std::mutex task_count_mutex[num_queues * 3];
  std::atomic_int done = 0;

  for (int i = 0; i < num_queues * 3; i++) {
    num_tasks[i] = 0;
    created[i] = false;
  }

  auto creation_func = [&] {
    for (int i = 0; i < num_queues; i++) {
      fml::TaskQueueId queue_id = task_queues->CreateTaskQueue();
      int limit = queue_id - base_queue_id;
      created[limit] = true;

      for (int cur_q = 1; cur_q < limit; cur_q++) {
        if (created[cur_q]) {
          std::scoped_lock counter(task_count_mutex[cur_q]);
          int cur_num_tasks = rand() % 10;
          for (int k = 0; k < cur_num_tasks; k++) {
            task_queues->RegisterTask(
                fml::TaskQueueId(base_queue_id + cur_q), [] {},
                fml::TimePoint::Now());
          }
          num_tasks[cur_q] += cur_num_tasks;
        }
      }
    }
    done++;
  };

  std::thread creation_1(creation_func);
  std::thread creation_2(creation_func);

  while (done < 2) {
    for (int i = 0; i < num_queues * 3; i++) {
      if (created[i]) {
        std::scoped_lock counter(task_count_mutex[i]);
        int num_pending = task_queues->GetNumPendingTasks(
            fml::TaskQueueId(base_queue_id + i));
        int num_added = num_tasks[i];
        ASSERT_EQ(num_pending, num_added);
      }
    }
  }

  creation_1.join();
  creation_2.join();
}

TEST(MessageLoopTaskQueue, RegisterTaskWakesUpOwnerQueue) {
  auto task_queue = fml::MessageLoopTaskQueues::GetInstance();
  auto platform_queue = task_queue->CreateTaskQueue();
  auto raster_queue = task_queue->CreateTaskQueue();

  std::vector<fml::TimePoint> wakes;

  task_queue->SetWakeable(platform_queue,
                          new TestWakeable([&wakes](fml::TimePoint wake_time) {
                            wakes.push_back(wake_time);
                          }));

  task_queue->SetWakeable(raster_queue,
                          new TestWakeable([](fml::TimePoint wake_time) {
                            // The raster queue is owned by the platform queue.
                            ASSERT_FALSE(true);
                          }));

  auto time1 = fml::TimePoint::Now() + fml::TimeDelta::FromMilliseconds(1);
  auto time2 = fml::TimePoint::Now() + fml::TimeDelta::FromMilliseconds(2);

  ASSERT_EQ(0UL, wakes.size());

  task_queue->RegisterTask(
      platform_queue, []() {}, time1);

  ASSERT_EQ(1UL, wakes.size());
  ASSERT_EQ(time1, wakes[0]);

  task_queue->Merge(platform_queue, raster_queue);

  task_queue->RegisterTask(
      raster_queue, []() {}, time2);

  ASSERT_EQ(3UL, wakes.size());
  ASSERT_EQ(time1, wakes[1]);
  ASSERT_EQ(time1, wakes[2]);
}

}  // namespace testing
}  // namespace fml
