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
  ASSERT_TRUE(queue.PostJobForDescriptor(desc, [&](bool) {
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

  queue->PostJobForDescriptor(desc1, [&](bool) {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc2, [&](bool) {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc3, [&](bool) {
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

  queue->PostJobForDescriptor(desc, [&](bool) {
    first_job_count++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc, [&](bool) {
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
                              [&](bool) { latch.CountDown(); });

  latch.Wait();

  fml::CountDownLatch latch2(1);
  queue->PostJobForDescriptor(PipelineDescriptor{},
                              [&](bool) { latch2.CountDown(); });

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

    queue->PostJobForDescriptor(desc1, [&](bool) {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    queue->PostJobForDescriptor(desc2, [&](bool) {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    queue->PostJobForDescriptor(desc3, [&](bool) {
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

  queue->PostJobForDescriptor(desc1, [&](bool) {
    first_job_started.Signal();
    block_first_job.Wait();
  });
  first_job_started.Wait();
  processing_while_running.store(queue->IsProcessingJobs());

  queue->PostJobForDescriptor(desc2, [&](bool) {});
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

TEST(PipelineCompileQueueGLESTest, PassesEagerOnlyFromPerformJobEagerly) {
  fml::Thread thread;
  std::shared_ptr<PipelineCompileQueueGLES> queue =
      PipelineCompileQueueGLES::Create(CreateBasicTaskRunner(thread));
  ASSERT_NE(queue, nullptr);

  PipelineDescriptor blocking_desc;
  blocking_desc.SetCullMode(CullMode::kNone);
  PipelineDescriptor eager_desc;
  eager_desc.SetCullMode(CullMode::kFrontFace);
  PipelineDescriptor queued_desc;
  queued_desc.SetCullMode(CullMode::kBackFace);

  fml::AutoResetWaitableEvent blocking_started;
  fml::AutoResetWaitableEvent blocking_may_finish;
  fml::AutoResetWaitableEvent queued_done;
  std::atomic<bool> eager_value{false};
  std::atomic<bool> queued_value{true};

  // The first job holds the queue, so eager_desc is still pending when this
  // thread takes it
  queue->PostJobForDescriptor(blocking_desc, [&](bool) {
    blocking_started.Signal();
    blocking_may_finish.Wait();
  });
  blocking_started.Wait();
  queue->PostJobForDescriptor(eager_desc,
                              [&](bool eager) { eager_value.store(eager); });
  queue->PostJobForDescriptor(queued_desc, [&](bool eager) {
    queued_value.store(eager);
    queued_done.Signal();
  });

  queue->PerformJobEagerly(eager_desc);
  blocking_may_finish.Signal();
  queued_done.Wait();

  EXPECT_TRUE(eager_value.load());
  EXPECT_FALSE(queued_value.load());

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

  std::atomic<int> own_count{-1};
  std::atomic<int> other_count{-1};
  fml::AutoResetWaitableEvent job_started;
  fml::AutoResetWaitableEvent job_may_finish;

  first->PostJob([&]() {
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
