// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include <atomic>
#include <memory>
#include <vector>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/task_runner_util.h"
#include "flutter/fml/thread.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

namespace {

std::shared_ptr<fml::BasicTaskRunner> CreateBasicTaskRunner(
    const fml::Thread& thread) {
  return std::make_shared<fml::WrapperBasicTaskRunner>(thread.GetTaskRunner());
}

void PostJobSync(PipelineCompileQueueGLES& queue, const fml::closure& job) {
  fml::AutoResetWaitableEvent latch;
  queue.PostJob([&]() {
    job();
    latch.Signal();
  });
  latch.Wait();
}

void PostJobForDescriptorSync(PipelineCompileQueueGLES& queue,
                              const PipelineDescriptor& desc,
                              const fml::closure& job) {
  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(queue.PostJobForDescriptor(desc, [&]() {
    job();
    latch.Signal();
  }));
  latch.Wait();
}

}  // namespace

TEST(PipelineCompileQueueGLESTest, CreateReturnsNullWithNullTaskRunner) {
  auto queue = PipelineCompileQueueGLES::Create(nullptr);
  EXPECT_EQ(queue, nullptr);
}

TEST(PipelineCompileQueueGLESTest, CreateSucceedsWithValidTaskRunner) {
  fml::Thread thread;
  auto queue = PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  EXPECT_NE(queue, nullptr);
  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, PostJobDoesNothingWithNullClosure) {
  fml::Thread thread;
  auto queue = PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);
  queue->PostJob(nullptr);
  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, OnJobAddedProcessesJobsSequentially) {
  fml::Thread thread;
  auto queue = PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  std::atomic<int> completed_jobs{0};
  fml::CountDownLatch latch(3);

  PipelineDescriptor desc1;
  desc1.SetSampleCount(SampleCount::kCount1);
  desc1.SetCullMode(CullMode::kNone);

  PipelineDescriptor desc2;
  desc2.SetSampleCount(SampleCount::kCount1);
  desc2.SetCullMode(CullMode::kFrontFace);

  PipelineDescriptor desc3;
  desc3.SetSampleCount(SampleCount::kCount1);
  desc3.SetCullMode(CullMode::kBackFace);

  queue->PostJobForDescriptor(desc1, [&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc2, [&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc3, [&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  latch.Wait();

  EXPECT_EQ(completed_jobs, 3);

  thread.Join();
}

TEST(PipelineCompileQueueGLESTest,
     PostJobForDescriptorWithDuplicateRunsEagerly) {
  fml::Thread thread;
  auto queue = PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  std::atomic<int> first_job_count{0};
  std::atomic<int> second_job_count{0};
  fml::CountDownLatch latch(2);

  PipelineDescriptor desc;

  queue->PostJobForDescriptor(desc, [&]() {
    first_job_count++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc, [&]() {
    second_job_count++;
    latch.CountDown();
  });

  latch.Wait();

  EXPECT_EQ(first_job_count, 1);
  EXPECT_EQ(second_job_count, 1);
  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, IsProcessingResetsAfterAllJobsComplete) {
  fml::Thread thread;
  auto queue = PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  fml::CountDownLatch latch(1);

  queue->PostJobForDescriptor(PipelineDescriptor{},
                              [&]() { latch.CountDown(); });

  latch.Wait();

  fml::CountDownLatch latch2(1);
  queue->PostJobForDescriptor(PipelineDescriptor{},
                              [&]() { latch2.CountDown(); });

  latch2.Wait();

  SUCCEED();
  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, DestroyQueueWithPendingTasks) {
  fml::Thread thread;
  std::atomic<int> completed_jobs{0};
  fml::CountDownLatch latch(3);

  {
    auto queue =
        PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
    ASSERT_NE(queue, nullptr);

    PipelineDescriptor desc1;
    desc1.SetSampleCount(SampleCount::kCount1);
    desc1.SetCullMode(CullMode::kNone);

    PipelineDescriptor desc2;
    desc2.SetSampleCount(SampleCount::kCount1);
    desc2.SetCullMode(CullMode::kFrontFace);

    PipelineDescriptor desc3;
    desc3.SetSampleCount(SampleCount::kCount1);
    desc3.SetCullMode(CullMode::kBackFace);

    queue->PostJobForDescriptor(desc1, [&]() {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    queue->PostJobForDescriptor(desc2, [&]() {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    queue->PostJobForDescriptor(desc3, [&]() {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    // Queue will be destroyed here with pending jobs.
    // The destructor should ensure that the pending jobs are either executed
    // or posted to the queue's thread.
  }

  // Wait for completion of the jobs.
  latch.Wait();
  EXPECT_EQ(completed_jobs, 3);

  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, ReportsProcessingAndCallsOnDrained) {
  fml::Thread thread;
  std::shared_ptr<PipelineCompileQueueGLES> queue =
      PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  fml::AutoResetWaitableEvent block_first_job;
  fml::AutoResetWaitableEvent first_job_started;
  fml::AutoResetWaitableEvent drained;
  std::atomic<int> drained_count{0};
  std::atomic<bool> processing_while_running{false};

  queue->SetOnDrained([&]() {
    drained_count.fetch_add(1);
    drained.Signal();
  });

  EXPECT_FALSE(queue->IsProcessingJobs());

  PipelineDescriptor desc1;
  desc1.SetCullMode(CullMode::kNone);
  PipelineDescriptor desc2;
  desc2.SetCullMode(CullMode::kFrontFace);

  queue->PostJobForDescriptor(desc1, [&]() {
    first_job_started.Signal();
    block_first_job.Wait();
  });
  first_job_started.Wait();
  processing_while_running.store(queue->IsProcessingJobs());

  queue->PostJobForDescriptor(desc2, [&]() {});
  block_first_job.Signal();
  drained.Wait();

  EXPECT_TRUE(processing_while_running.load());
  EXPECT_EQ(drained_count.load(), 1);
  EXPECT_FALSE(queue->IsProcessingJobs());

  // A cleared callback is not called again.
  queue->SetOnDrained(nullptr);
  PostJobForDescriptorSync(*queue, PipelineDescriptor{}, []() {});

  // The drain report follows the last job, so the count is read once the
  // thread that would send it is gone.
  thread.Join();
  EXPECT_EQ(drained_count.load(), 1);
}

TEST(PipelineCompileQueueGLESTest, ReportsRunningJobOnlyInsideJobs) {
  fml::Thread thread;
  std::shared_ptr<PipelineCompileQueueGLES> queue =
      PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  bool in_posted_job = false;
  bool in_descriptor_job = false;
  bool in_plain_task = true;

  PostJobSync(*queue,
              [&]() { in_posted_job = queue->IsRunningJobOnCurrentThread(); });
  PostJobForDescriptorSync(*queue, PipelineDescriptor{}, [&]() {
    in_descriptor_job = queue->IsRunningJobOnCurrentThread();
  });

  // A task posted to the same thread without the queue is not a job.
  flutter::testing::PostTaskSync(thread.GetTaskRunner(), [&]() {
    in_plain_task = queue->IsRunningJobOnCurrentThread();
  });

  EXPECT_TRUE(in_posted_job);
  EXPECT_TRUE(in_descriptor_job);
  EXPECT_FALSE(in_plain_task);
  EXPECT_FALSE(queue->IsRunningJobOnCurrentThread());

  thread.Join();
}

TEST(PipelineCompileQueueGLESTest, JobsOfOneQueueAreInvisibleToAnother) {
  fml::Thread first_thread;
  fml::Thread second_thread;
  std::shared_ptr<PipelineCompileQueueGLES> first =
      PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(first_thread));
  std::shared_ptr<PipelineCompileQueueGLES> second =
      PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(second_thread));
  ASSERT_NE(first, nullptr);
  ASSERT_NE(second, nullptr);

  std::atomic<bool> running_on_own_queue{false};
  std::atomic<bool> running_on_other_queue{true};
  std::atomic<int> own_count{-1};
  std::atomic<int> other_count{-1};
  fml::AutoResetWaitableEvent job_started;
  fml::AutoResetWaitableEvent job_may_finish;

  first->PostJob([&]() {
    running_on_own_queue.store(first->IsRunningJobOnCurrentThread());
    running_on_other_queue.store(second->IsRunningJobOnCurrentThread());
    own_count.store(first->RunningJobCount());
    other_count.store(second->RunningJobCount());
    job_started.Signal();
    job_may_finish.Wait();
  });
  job_started.Wait();

  // The second queue runs nothing, even though another queue does.
  EXPECT_EQ(second->RunningJobCount(), 0);
  job_may_finish.Signal();

  PostJobSync(*first, []() {});

  EXPECT_TRUE(running_on_own_queue.load());
  EXPECT_FALSE(running_on_other_queue.load());
  EXPECT_EQ(own_count.load(), 1);
  EXPECT_EQ(other_count.load(), 0);

  first_thread.Join();
  second_thread.Join();

  // The job signals from inside itself and the count drops after it returns,
  // so the count is read once the thread that ran it is gone.
  EXPECT_EQ(first->RunningJobCount(), 0);
}

}  // namespace testing
}  // namespace impeller
