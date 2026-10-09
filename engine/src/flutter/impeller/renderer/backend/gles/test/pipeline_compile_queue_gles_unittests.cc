// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include <atomic>
#include <chrono>
#include <deque>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/task_runner_util.h"
#include "flutter/fml/thread.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

namespace {

std::shared_ptr<fml::BasicTaskRunner> CreateBasicTaskRunner(
    const fml::Thread& thread) {
  return std::make_shared<fml::WrapperBasicTaskRunner>(thread.GetTaskRunner());
}

/// A task runner that captures posted tasks so tests can run them on demand.
class CapturingTaskRunner final : public fml::BasicTaskRunner {
 public:
  void PostTask(const fml::closure& task) override { tasks_.push_back(task); }

  /// Runs tasks (including ones posted while running) until none remain.
  /// Returns the number of tasks that were run.
  size_t RunAll() {
    size_t count = 0;
    while (!tasks_.empty()) {
      RunOne();
      count++;
    }
    return count;
  }

  void RunOne() {
    fml::closure task = std::move(tasks_.front());
    tasks_.pop_front();
    task();
  }

  size_t PendingTaskCount() const { return tasks_.size(); }

 private:
  std::deque<fml::closure> tasks_;
};

class MockCompileJob : public PipelineCompileQueueGLES::CompileJob {
 public:
  MOCK_METHOD(absl::Status, Start, (), (override));
  MOCK_METHOD(void, Finish, (), (override));
};

/// Posts a job whose work is done entirely in its start step.
bool PostJob(PipelineCompileQueueGLES& queue,
             const PipelineDescriptor& desc,
             const fml::closure& start) {
  auto job = std::make_unique<::testing::NiceMock<MockCompileJob>>();
  ON_CALL(*job, Start())
      .WillByDefault(::testing::DoAll(::testing::InvokeWithoutArgs(start),
                                      ::testing::Return(absl::OkStatus())));
  return queue.PostJobForDescriptor(desc, std::move(job));
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

TEST(PipelineCompileQueueGLESTest, KeepsAtMostOneTaskOutstanding) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  int executed = 0;
  for (int i = 0; i < 3; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(PostJob(*queue, desc, [&executed]() { executed++; }));
  }
  EXPECT_EQ(runner->PendingTaskCount(), 1u);

  runner->RunAll();
  EXPECT_EQ(executed, 3);

  // Once drained, a new job must restart processing.
  ASSERT_TRUE(
      PostJob(*queue, PipelineDescriptor{}, [&executed]() { executed++; }));
  EXPECT_EQ(runner->PendingTaskCount(), 1u);
  runner->RunAll();
  EXPECT_EQ(executed, 4);
}

TEST(PipelineCompileQueueGLESTest, ProcessesJobsSequentially) {
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

  PostJob(*queue, desc1, [&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  PostJob(*queue, desc2, [&]() {
    std::this_thread::sleep_for(std::chrono::milliseconds(80));
    completed_jobs++;
    latch.CountDown();
  });

  PostJob(*queue, desc3, [&]() {
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

  PostJob(*queue, desc, [&]() {
    first_job_count++;
    latch.CountDown();
  });

  PostJob(*queue, desc, [&]() {
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

  PostJob(*queue, PipelineDescriptor{}, [&]() { latch.CountDown(); });

  latch.Wait();

  fml::CountDownLatch latch2(1);
  PostJob(*queue, PipelineDescriptor{}, [&]() { latch2.CountDown(); });

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

    PostJob(*queue, desc1, [&]() {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    PostJob(*queue, desc2, [&]() {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      completed_jobs++;
      latch.CountDown();
    });

    PostJob(*queue, desc3, [&]() {
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

TEST(PipelineCompileQueueGLESTest, PostJobForDescriptorRejectsNullJob) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  EXPECT_FALSE(queue->PostJobForDescriptor(PipelineDescriptor{}, nullptr));
  EXPECT_EQ(runner->RunAll(), 0u);
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlyExecutesPendingJob) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  PipelineDescriptor desc;
  int executed = 0;
  ASSERT_TRUE(PostJob(*queue, desc, [&executed]() { executed++; }));
  EXPECT_EQ(executed, 0);

  queue->PerformJobEagerly(desc);
  EXPECT_EQ(executed, 1);

  // The posted drain task must not execute the job a second time.
  runner->RunAll();
  EXPECT_EQ(executed, 1);
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlyIgnoresUnknownDescriptor) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  queue->PerformJobEagerly(PipelineDescriptor{});
  EXPECT_EQ(runner->RunAll(), 0u);
}

TEST(PipelineCompileQueueGLESTest, ExecutesJobsInInsertionOrder) {
  constexpr size_t kJobCount = 10;
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  std::vector<size_t> job_order;
  for (size_t i = 0; i < kJobCount; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(PostJob(*queue, desc, [&job_order, index = i]() {
      job_order.push_back(index);
    }));
  }

  runner->RunAll();

  ASSERT_EQ(job_order.size(), kJobCount);
  for (size_t i = 0; i < kJobCount; i++) {
    EXPECT_EQ(i, job_order[i]);
  }
}

TEST(PipelineCompileQueueGLESTest, DestructorFinishesPendingJobs) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  int executed = 0;
  ASSERT_TRUE(
      PostJob(*queue, PipelineDescriptor{}, [&executed]() { executed++; }));
  EXPECT_EQ(executed, 0);

  queue.reset();
  EXPECT_EQ(executed, 1);

  // Outstanding tasks hold a weak reference and must be no-ops now.
  runner->RunAll();
  EXPECT_EQ(executed, 1);
}

TEST(PipelineCompileQueueGLESTest, WorkerRunsFinishAsSeparateTask) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  ::testing::MockFunction<void()> after_first_task;
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*job, Start());
    EXPECT_CALL(after_first_task, Call());
    EXPECT_CALL(*job, Finish());
  }
  ASSERT_TRUE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, std::move(job)));

  runner->RunOne();
  after_first_task.Call();
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, CreateReturnsNullWithZeroMaxActiveJobs) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  EXPECT_EQ(PipelineCompileQueueGLES::Create(runner, /*max_active_jobs=*/0),
            nullptr);
}

TEST(PipelineCompileQueueGLESTest, OneActiveJobFinishesBeforeStartingNext) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner, /*max_active_jobs=*/1);
  ASSERT_NE(queue, nullptr);

  ::testing::InSequence sequence;
  for (int i = 0; i < 2; i++) {
    auto job = std::make_unique<MockCompileJob>();
    EXPECT_CALL(*job, Start());
    EXPECT_CALL(*job, Finish());
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(job)));
  }
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, StartsUpToMaxActiveJobsBeforeFinishing) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner, /*max_active_jobs=*/2);
  ASSERT_NE(queue, nullptr);

  std::vector<std::unique_ptr<MockCompileJob>> jobs;
  for (int i = 0; i < 3; i++) {
    jobs.push_back(std::make_unique<MockCompileJob>());
  }
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jobs[0], Start());
    EXPECT_CALL(*jobs[1], Start());
    EXPECT_CALL(*jobs[0], Finish());
    EXPECT_CALL(*jobs[2], Start());
    EXPECT_CALL(*jobs[1], Finish());
    EXPECT_CALL(*jobs[2], Finish());
  }
  for (int i = 0; i < 3; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(jobs[i])));
  }
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlyRunsStartAndFinish) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  ::testing::MockFunction<void()> after_perform;
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*job, Start());
    EXPECT_CALL(*job, Finish());
    EXPECT_CALL(after_perform, Call());
  }
  PipelineDescriptor desc;
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(job)));

  queue->PerformJobEagerly(desc);
  after_perform.Call();
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, DestructorRunsStartAndFinish) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  ::testing::MockFunction<void()> after_reset;
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*job, Start());
    EXPECT_CALL(*job, Finish());
    EXPECT_CALL(after_reset, Call());
  }
  ASSERT_TRUE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, std::move(job)));

  queue.reset();
  after_reset.Call();
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlyWaitsForActiveJob) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  const std::thread::id worker_thread_id = std::this_thread::get_id();
  auto job = std::make_unique<MockCompileJob>();
  EXPECT_CALL(*job, Start());
  EXPECT_CALL(*job, Finish()).WillOnce([worker_thread_id]() {
    // The job is finished by the worker, not by the waiting thread.
    EXPECT_EQ(std::this_thread::get_id(), worker_thread_id);
  });
  PipelineDescriptor desc;
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(job)));
  runner->RunOne();  // Starts the job.

  std::atomic<bool> performed = false;
  std::thread waiter([&queue, &desc, &performed]() {
    queue->PerformJobEagerly(desc);
    performed = true;
  });
  // Give the waiter a chance to block on the active job.
  std::this_thread::sleep_for(std::chrono::milliseconds(20));
  EXPECT_FALSE(performed);

  runner->RunAll();  // Finishes the job.
  waiter.join();
  EXPECT_TRUE(performed);
}

TEST(PipelineCompileQueueGLESTest, AwaitedActiveJobIsFinishedFirst) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner, /*max_active_jobs=*/3);
  ASSERT_NE(queue, nullptr);

  std::vector<std::unique_ptr<MockCompileJob>> jobs;
  for (int i = 0; i < 3; i++) {
    jobs.push_back(std::make_unique<MockCompileJob>());
  }
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*jobs[0], Start());
    EXPECT_CALL(*jobs[1], Start());
    // Job 1 is awaited, so it is finished before the older job 0 and before
    // job 2 is started.
    EXPECT_CALL(*jobs[1], Finish());
    EXPECT_CALL(*jobs[2], Start());
    EXPECT_CALL(*jobs[0], Finish());
    EXPECT_CALL(*jobs[2], Finish());
  }
  std::vector<PipelineDescriptor> descs(3);
  for (int i = 0; i < 3; i++) {
    descs[i].SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->PostJobForDescriptor(descs[i], std::move(jobs[i])));
  }
  runner->RunOne();  // Starts job 0.
  runner->RunOne();  // Starts job 1.

  std::thread waiter(
      [&queue, &descs]() { queue->PerformJobEagerly(descs[1]); });
  // Give the waiter a chance to mark job 1 as awaited.
  std::this_thread::sleep_for(std::chrono::milliseconds(50));

  runner->RunAll();
  waiter.join();
}

TEST(PipelineCompileQueueGLESTest, DestructorFinishesActiveJobsOnWorker) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  ::testing::MockFunction<void()> after_reset;
  {
    ::testing::InSequence sequence;
    EXPECT_CALL(*job, Start());
    EXPECT_CALL(after_reset, Call());
    EXPECT_CALL(*job, Finish());
  }
  ASSERT_TRUE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, std::move(job)));
  runner->RunOne();  // Starts the job.

  queue.reset();
  after_reset.Call();
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, DuplicateOfActiveJobRunsOnWorker) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto first_job = std::make_unique<MockCompileJob>();
  EXPECT_CALL(*first_job, Start());
  EXPECT_CALL(*first_job, Finish());
  auto second_job = std::make_unique<MockCompileJob>();
  EXPECT_CALL(*second_job, Start());
  EXPECT_CALL(*second_job, Finish());

  PipelineDescriptor desc;
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(first_job)));
  runner->RunOne();  // Starts the first job.
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(second_job)));
  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, WorkerSkipsFinishIfStartFails) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  EXPECT_CALL(*job, Start())
      .WillOnce(::testing::Return(absl::InternalError("Start failed.")));
  EXPECT_CALL(*job, Finish()).Times(0);
  ASSERT_TRUE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, std::move(job)));

  runner->RunAll();
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlySkipsFinishIfStartFails) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  auto job = std::make_unique<MockCompileJob>();
  EXPECT_CALL(*job, Start())
      .WillOnce(::testing::Return(absl::InternalError("Start failed.")));
  EXPECT_CALL(*job, Finish()).Times(0);
  PipelineDescriptor desc;
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, std::move(job)));

  queue->PerformJobEagerly(desc);
}

}  // namespace testing
}  // namespace impeller
