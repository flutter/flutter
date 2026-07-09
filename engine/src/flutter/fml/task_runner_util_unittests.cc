// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atomic>
#include <thread>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner_util.h"
#include "flutter/fml/thread.h"
#include "gtest/gtest.h"

namespace fml {
namespace testing {

TEST(TaskRunnerUtilTests, WrapperBasicTaskRunnerPostTask) {
  fml::Thread thread;

  WrapperBasicTaskRunner wrapper(thread.GetTaskRunner());

  std::thread::id wrapper_thread_id;
  wrapper.PostTask([&]() { wrapper_thread_id = std::this_thread::get_id(); });

  thread.Join();

  EXPECT_NE(wrapper_thread_id, std::this_thread::get_id());
}

TEST(TaskRunnerUtilTests, ConditionalBasicTaskRunnerPostTask) {
  fml::Thread thread;
  std::atomic_bool active = true;
  ConditionalBasicTaskRunner runner(thread.GetTaskRunner(),
                                    [&active]() -> bool { return active; });

  fml::AutoResetWaitableEvent latch;
  std::atomic_bool task1_called = false;
  runner.PostTask([&]() {
    task1_called = true;
    latch.Signal();
  });
  latch.Wait();

  active = false;

  std::atomic_bool task2_called = false;
  runner.PostTask([&]() { task2_called = true; });

  thread.GetTaskRunner()->PostTask([&]() { latch.Signal(); });
  latch.Wait();

  thread.Join();

  EXPECT_TRUE(task1_called);
  EXPECT_FALSE(task2_called);
}

}  // namespace testing
}  // namespace fml
