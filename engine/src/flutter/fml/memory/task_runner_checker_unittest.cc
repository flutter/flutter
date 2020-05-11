// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <gtest/gtest.h>

#include <thread>
#include "flutter/fml/memory/task_runner_checker.h"

#include "flutter/fml/message_loop.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"

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

TEST(TaskRunnerCheckerTests, SameTaskRunnerRunsOnTheSameThread) {
  fml::MessageLoop& loop1 = fml::MessageLoop::GetCurrent();
  fml::MessageLoop& loop2 = fml::MessageLoop::GetCurrent();
  TaskQueueId a = loop1.GetTaskRunner()->GetTaskQueueId();
  TaskQueueId b = loop2.GetTaskRunner()->GetTaskQueueId();
  EXPECT_EQ(TaskRunnerChecker::RunsOnTheSameThread(a, b), true);
}

TEST(TaskRunnerCheckerTests, RunsOnDifferentThreadsReturnsFalse) {
  fml::MessageLoop& loop1 = fml::MessageLoop::GetCurrent();
  TaskQueueId a = loop1.GetTaskRunner()->GetTaskQueueId();
  fml::AutoResetWaitableEvent latch;
  std::thread anotherThread([&]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    fml::MessageLoop& loop2 = fml::MessageLoop::GetCurrent();
    TaskQueueId b = loop2.GetTaskRunner()->GetTaskQueueId();
    EXPECT_EQ(TaskRunnerChecker::RunsOnTheSameThread(a, b), false);
    latch.Signal();
  });
  latch.Wait();
  anotherThread.join();
}

TEST(TaskRunnerCheckerTests, MergedTaskRunnersRunsOnTheSameThread) {
  fml::MessageLoop* loop1 = nullptr;
  fml::AutoResetWaitableEvent latch1;
  fml::AutoResetWaitableEvent term1;
  std::thread thread1([&loop1, &latch1, &term1]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop1 = &fml::MessageLoop::GetCurrent();
    latch1.Signal();
    term1.Wait();
  });

  fml::MessageLoop* loop2 = nullptr;
  fml::AutoResetWaitableEvent latch2;
  fml::AutoResetWaitableEvent term2;
  std::thread thread2([&loop2, &latch2, &term2]() {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    loop2 = &fml::MessageLoop::GetCurrent();
    latch2.Signal();
    term2.Wait();
  });

  latch1.Wait();
  latch2.Wait();
  fml::TaskQueueId qid1 = loop1->GetTaskRunner()->GetTaskQueueId();
  fml::TaskQueueId qid2 = loop2->GetTaskRunner()->GetTaskQueueId();
  const auto raster_thread_merger_ =
      fml::MakeRefCounted<fml::RasterThreadMerger>(qid1, qid2);
  const int kNumFramesMerged = 5;

  raster_thread_merger_->MergeWithLease(kNumFramesMerged);

  // merged, running on the same thread
  EXPECT_EQ(TaskRunnerChecker::RunsOnTheSameThread(qid1, qid2), true);

  for (int i = 0; i < kNumFramesMerged; i++) {
    ASSERT_TRUE(raster_thread_merger_->IsMerged());
    raster_thread_merger_->DecrementLease();
  }

  ASSERT_FALSE(raster_thread_merger_->IsMerged());

  // un-merged, not running on the same thread
  EXPECT_EQ(TaskRunnerChecker::RunsOnTheSameThread(qid1, qid2), false);

  term1.Signal();
  term2.Signal();
  thread1.join();
  thread2.join();
}

}  // namespace testing
}  // namespace fml
