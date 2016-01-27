// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/message_loop_test_helper.h"

#include <thread>
#include <vector>

#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/util/ref_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::util::RefPtr;

namespace mojo {
namespace platform {
namespace test {

void MessageLoopTestHelper(MessageLoop* message_loop) {
  RefPtr<TaskRunner> task_runner = message_loop->GetTaskRunner();
  EXPECT_TRUE(task_runner);

  // |GetTaskRunner()| should always return the same |TaskRunner()|.
  EXPECT_EQ(task_runner, message_loop->GetTaskRunner());

  std::vector<int> stuff;
  task_runner->PostTask([&stuff, message_loop, &task_runner]() {
    EXPECT_TRUE(message_loop->IsRunningOnCurrentThread());
    stuff.push_back(1);
    task_runner->PostTask([&stuff]() { stuff.push_back(3); });
    message_loop->QuitWhenIdle();
  });
  task_runner->PostTask([&stuff]() { stuff.push_back(2); });
  EXPECT_TRUE(stuff.empty());
  message_loop->Run();
  EXPECT_EQ(std::vector<int>({1, 2, 3}), stuff);

  stuff.clear();
  task_runner->PostTask([&stuff, message_loop, &task_runner]() {
    EXPECT_TRUE(message_loop->IsRunningOnCurrentThread());
    stuff.push_back(4);
    task_runner->PostTask([&stuff]() { stuff.push_back(6); });
  });
  task_runner->PostTask([&stuff]() { stuff.push_back(5); });
  message_loop->RunUntilIdle();
  EXPECT_EQ(std::vector<int>({4, 5, 6}), stuff);

  stuff.clear();
  task_runner->PostTask([&stuff, message_loop, &task_runner]() {
    EXPECT_TRUE(message_loop->IsRunningOnCurrentThread());
    stuff.push_back(7);
    message_loop->QuitNow();
    task_runner->PostTask([&stuff]() { stuff.push_back(9); });
  });
  task_runner->PostTask([&stuff]() { stuff.push_back(8); });
  message_loop->Run();
  EXPECT_EQ(std::vector<int>({7}), stuff);
  stuff.clear();
  message_loop->RunUntilIdle();
  EXPECT_EQ(std::vector<int>({8, 9}), stuff);

  stuff.clear();
  message_loop->RunUntilIdle();
  EXPECT_TRUE(stuff.empty());

  {
    std::thread other_thread([message_loop]() {
      // |IsRunningOnCurrentThread()| may be called on any thread.
      EXPECT_FALSE(message_loop->IsRunningOnCurrentThread());
    });
    other_thread.join();
  }

  stuff.clear();
  task_runner->PostTask([&stuff, message_loop, &task_runner]() {
    EXPECT_TRUE(message_loop->IsRunningOnCurrentThread());
    std::thread other_thread([&stuff, message_loop, task_runner]() {
      EXPECT_FALSE(message_loop->IsRunningOnCurrentThread());
      EXPECT_EQ(task_runner, message_loop->GetTaskRunner());
      stuff.push_back(10);
      task_runner->PostTask([&stuff, message_loop]() {
        EXPECT_TRUE(message_loop->IsRunningOnCurrentThread());
        stuff.push_back(11);
        message_loop->QuitWhenIdle();
      });
    });
    other_thread.join();
    EXPECT_EQ(std::vector<int>({10}), stuff);
    stuff.clear();
  });
  message_loop->Run();
  EXPECT_EQ(std::vector<int>({11}), stuff);
}

}  // namespace test
}  // namespace platform
}  // namespace mojo
