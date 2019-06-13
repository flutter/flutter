// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queue.h"
#include "gtest/gtest.h"

TEST(MessageLoopTaskQueue, StartsWithNoPendingTasks) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  ASSERT_FALSE(task_queue->HasPendingTasks());
}

TEST(MessageLoopTaskQueue, RegisterOneTask) {
  auto task_queue = std::make_unique<fml::MessageLoopTaskQueue>();
  const auto time = fml::TimePoint::Max();
  const auto wake_time = task_queue->RegisterTask([] {}, time);
  ASSERT_TRUE(task_queue->HasPendingTasks());
  ASSERT_TRUE(task_queue->GetNumPendingTasks() == 1);
  ASSERT_TRUE(wake_time == time);
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
