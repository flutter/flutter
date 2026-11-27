// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <atomic>
#include <cstdint>
#include <memory>
#include <thread>
#include <type_traits>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/task_source.h"
#include "flutter/fml/time/chrono_timestamp_provider.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "gtest/gtest.h"

namespace fml {
namespace testing {

TEST(TaskSourceTests, SimpleInitialization) {
  TaskSource task_source = TaskSource(TaskQueueId(1));
  task_source.RegisterTask(
      {1, [] {}, ChronoTicksSinceEpoch(), TaskSourceGrade::kUnspecified});
  ASSERT_EQ(task_source.GetNumPendingTasks(), 1u);
}

TEST(TaskSourceTests, MultipleTaskGrades) {
  TaskSource task_source = TaskSource(TaskQueueId(1));
  task_source.RegisterTask(
      {1, [] {}, ChronoTicksSinceEpoch(), TaskSourceGrade::kUnspecified});
  task_source.RegisterTask(
      {2, [] {}, ChronoTicksSinceEpoch(), TaskSourceGrade::kUserInteraction});
  task_source.RegisterTask(
      {3, [] {}, ChronoTicksSinceEpoch(), TaskSourceGrade::kDartEventLoop});
  ASSERT_EQ(task_source.GetNumPendingTasks(), 3u);
}

TEST(TaskSourceTests, SimpleOrdering) {
  TaskSource task_source = TaskSource(TaskQueueId(1));
  auto time_stamp = ChronoTicksSinceEpoch();
  int value = 0;
  task_source.RegisterTask(
      {1, [&] { value = 1; }, time_stamp, TaskSourceGrade::kUnspecified});
  task_source.RegisterTask({2, [&] { value = 7; },
                            time_stamp + fml::TimeDelta::FromMilliseconds(1),
                            TaskSourceGrade::kUnspecified});
  task_source.Top().task.GetTask()();
  task_source.PopTask(TaskSourceGrade::kUnspecified);
  ASSERT_EQ(value, 1);
  task_source.Top().task.GetTask()();
  task_source.PopTask(TaskSourceGrade::kUnspecified);
  ASSERT_EQ(value, 7);
}

TEST(TaskSourceTests, SimpleOrderingMultiTaskHeaps) {
  TaskSource task_source = TaskSource(TaskQueueId(1));
  auto time_stamp = ChronoTicksSinceEpoch();
  int value = 0;
  task_source.RegisterTask(
      {1, [&] { value = 1; }, time_stamp, TaskSourceGrade::kDartEventLoop});
  task_source.RegisterTask({2, [&] { value = 7; },
                            time_stamp + fml::TimeDelta::FromMilliseconds(1),
                            TaskSourceGrade::kUserInteraction});
  auto top_task = task_source.Top();
  top_task.task.GetTask()();
  task_source.PopTask(top_task.task.GetTaskSourceGrade());
  ASSERT_EQ(value, 1);

  auto second_task = task_source.Top();
  second_task.task.GetTask()();
  task_source.PopTask(second_task.task.GetTaskSourceGrade());
  ASSERT_EQ(value, 7);
}

TEST(TaskSourceTests, OrderingMultiTaskHeapsSecondaryPaused) {
  TaskSource task_source = TaskSource(TaskQueueId(1));
  auto time_stamp = ChronoTicksSinceEpoch();
  int value = 0;
  task_source.RegisterTask(
      {1, [&] { value = 1; }, time_stamp, TaskSourceGrade::kDartEventLoop});
  task_source.RegisterTask({2, [&] { value = 7; },
                            time_stamp + fml::TimeDelta::FromMilliseconds(1),
                            TaskSourceGrade::kUserInteraction});

  task_source.PauseSecondary();

  auto top_task = task_source.Top();
  top_task.task.GetTask()();
  task_source.PopTask(top_task.task.GetTaskSourceGrade());
  ASSERT_EQ(value, 7);

  ASSERT_TRUE(task_source.IsEmpty());

  task_source.ResumeSecondary();

  auto second_task = task_source.Top();
  second_task.task.GetTask()();
  task_source.PopTask(second_task.task.GetTaskSourceGrade());
  ASSERT_EQ(value, 1);
}

TEST(TaskSourceTests, NonSboClosuresAreMovedWithoutCopying) {
  static_assert(std::is_nothrow_move_constructible_v<DelayedTask>,
                "DelayedTask must be nothrow movable for vector reallocations");

  struct CopyCountingCallable {
    std::shared_ptr<int> copies;
    std::array<uint8_t, 64> payload{};
    int id = 0;
    std::vector<int>* order = nullptr;

    CopyCountingCallable(std::shared_ptr<int> c,
                         int task_id,
                         std::vector<int>* order_out)
        : copies(std::move(c)), id(task_id), order(order_out) {}

    CopyCountingCallable(const CopyCountingCallable& other)
        : copies(other.copies),
          payload(other.payload),
          id(other.id),
          order(other.order) {
      ++(*copies);
    }

    CopyCountingCallable(CopyCountingCallable&&) noexcept = default;
    CopyCountingCallable& operator=(const CopyCountingCallable&) = default;
    CopyCountingCallable& operator=(CopyCountingCallable&&) noexcept = default;

    void operator()() const { order->push_back(id); }
  };

  const auto base = ChronoTicksSinceEpoch();
  constexpr int kNumTasks = 32;
  std::vector<int> expected_order;
  expected_order.reserve(kNumTasks);
  for (int i = kNumTasks; i >= 1; --i) {
    expected_order.push_back(i);
  }

  // Exercise both primary (kUnspecified) and secondary (kDartEventLoop) heaps.
  for (TaskSourceGrade grade :
       {TaskSourceGrade::kUnspecified, TaskSourceGrade::kDartEventLoop}) {
    auto copy_count = std::make_shared<int>(0);
    std::vector<int> order;
    TaskSource task_source(TaskQueueId(1));

    // Reverse timestamps force heap sift-up and vector reallocations.
    for (int i = 1; i <= kNumTasks; ++i) {
      fml::closure task(CopyCountingCallable(copy_count, i, &order));
      task_source.RegisterTask({static_cast<size_t>(i), std::move(task),
                                base - fml::TimeDelta::FromMicroseconds(i),
                                grade});
    }

    for (int i = 0; i < kNumTasks; ++i) {
      auto top = task_source.Top();
      fml::closure invocation =
          task_source.PopTask(top.task.GetTaskSourceGrade());
      invocation();
    }

    EXPECT_EQ(*copy_count, 0);
    EXPECT_EQ(order, expected_order);
  }

  // Exercise end-to-end MessageLoopTaskQueues RegisterTask -> GetNextTaskToRun.
  auto task_queues = MessageLoopTaskQueues::GetInstance();
  TaskQueueId queue_id = task_queues->CreateTaskQueue();
  ScopedCleanupClosure dispose_queue(
      [task_queues, queue_id] { task_queues->Dispose(queue_id); });

  auto copy_count = std::make_shared<int>(0);
  std::vector<int> order;
  for (int i = 1; i <= kNumTasks; ++i) {
    fml::closure task(CopyCountingCallable(copy_count, i, &order));
    task_queues->RegisterTask(queue_id, std::move(task),
                              base - fml::TimeDelta::FromMicroseconds(i),
                              (i % 2 == 0) ? TaskSourceGrade::kDartEventLoop
                                           : TaskSourceGrade::kUnspecified);
  }
  while (fml::closure invocation =
             task_queues->GetNextTaskToRun(queue_id, base)) {
    invocation();
  }
  EXPECT_EQ(*copy_count, 0);
  EXPECT_EQ(order, expected_order);
}

}  // namespace testing
}  // namespace fml
