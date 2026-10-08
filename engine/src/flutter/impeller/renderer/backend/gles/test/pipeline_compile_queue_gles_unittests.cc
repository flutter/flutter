// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include <atomic>
#include <deque>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/synchronization/count_down_latch.h"
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

/// Posts a job whose work is done entirely in its start step.
bool PostJob(PipelineCompileQueueGLES& queue,
             const PipelineDescriptor& desc,
             const fml::closure& start) {
  return queue.PostJobForDescriptor(desc, start, [] {});
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

  EXPECT_FALSE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, nullptr, [] {}));
  EXPECT_FALSE(
      queue->PostJobForDescriptor(PipelineDescriptor{}, [] {}, nullptr));
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

  std::vector<std::string> events;
  ASSERT_TRUE(queue->PostJobForDescriptor(
      PipelineDescriptor{}, [&events] { events.push_back("start"); },
      [&events] { events.push_back("finish"); }));

  runner->RunOne();
  EXPECT_EQ(events, std::vector<std::string>{"start"});
  EXPECT_GE(runner->PendingTaskCount(), 1u);

  runner->RunAll();
  EXPECT_EQ(events, (std::vector<std::string>{"start", "finish"}));
}

TEST(PipelineCompileQueueGLESTest, WorkerFinishesJobBeforeStartingNext) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  std::vector<std::string> events;
  for (int i = 0; i < 2; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->PostJobForDescriptor(
        desc, [&events, i] { events.push_back("start" + std::to_string(i)); },
        [&events, i] { events.push_back("finish" + std::to_string(i)); }));
  }
  runner->RunAll();

  EXPECT_EQ(events, (std::vector<std::string>{"start0", "finish0", "start1",
                                              "finish1"}));
}

TEST(PipelineCompileQueueGLESTest, PerformJobEagerlyRunsStartAndFinish) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  PipelineDescriptor desc;
  std::vector<std::string> events;
  ASSERT_TRUE(queue->PostJobForDescriptor(
      desc, [&events] { events.push_back("start"); },
      [&events] { events.push_back("finish"); }));
  queue->PerformJobEagerly(desc);
  EXPECT_EQ(events, (std::vector<std::string>{"start", "finish"}));

  runner->RunAll();
  EXPECT_EQ(events, (std::vector<std::string>{"start", "finish"}));
}

TEST(PipelineCompileQueueGLESTest, DestructorRunsStartAndFinish) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  std::vector<std::string> events;
  ASSERT_TRUE(queue->PostJobForDescriptor(
      PipelineDescriptor{}, [&events] { events.push_back("start"); },
      [&events] { events.push_back("finish"); }));
  queue.reset();

  EXPECT_EQ(events, (std::vector<std::string>{"start", "finish"}));
}

TEST(PipelineCompileQueueGLESTest, StartedJobCannotBePerformedEagerly) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueGLES::Create(runner);
  ASSERT_NE(queue, nullptr);

  PipelineDescriptor desc;
  int finished = 0;
  ASSERT_TRUE(
      queue->PostJobForDescriptor(desc, [] {}, [&finished] { finished++; }));
  runner->RunOne();

  // The finish step is waiting on the worker, so it isn't stolen.
  queue->PerformJobEagerly(desc);
  EXPECT_EQ(finished, 0);

  runner->RunAll();
  EXPECT_EQ(finished, 1);
}

}  // namespace testing
}  // namespace impeller
