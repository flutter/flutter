// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <thread>

#include "flutter/fml/memory/task_runner_checker.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"

#include <gtest/gtest.h>

namespace fml {
namespace testing {

TEST(TaskRunnerCheckerTests, RunsOnCurrentTaskRunner) {
  TaskRunnerChecker checker;
  EXPECT_EQ(checker.RunsOnCreationTaskRunner(), true);
}

TEST(TaskRunnerCheckerTests, FailsTheCheckIfOnDifferentTaskRunner) {
  TaskRunnerChecker checker;
  EXPECT_EQ(checker.RunsOnCreationTaskRunner(), true);
  fml::MessageLoop* loop = nullptr;
  fml::AutoResetWaitableEvent latch;
  std::thread anotherThread([&]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop = &fml::MessageLoop::GetCurrent();
    loop->GetTaskRunner()->PostTask([&]() {
      EXPECT_EQ(checker.RunsOnCreationTaskRunner(), false);
      latch.Signal();
    });
    loop->Run();
  });
  latch.Wait();
  loop->Terminate();
  anotherThread.join();
  EXPECT_EQ(checker.RunsOnCreationTaskRunner(), true);
}

}  // namespace testing
}  // namespace fml
