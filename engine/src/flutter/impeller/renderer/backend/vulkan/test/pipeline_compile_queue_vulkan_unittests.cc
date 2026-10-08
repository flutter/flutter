// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_compile_queue_vulkan.h"

#include <atomic>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/task_runner.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

namespace {

/// A task runner that captures posted tasks so tests can run them on demand.
class CapturingTaskRunner final : public fml::BasicTaskRunner {
 public:
  void PostTask(const fml::closure& task) override { tasks_.push_back(task); }

  /// Runs tasks (including ones posted while running) until none remain.
  /// Returns the number of tasks that were run.
  size_t RunAll() {
    size_t count = 0;
    while (!tasks_.empty()) {
      auto task = std::move(tasks_.front());
      tasks_.pop_front();
      task();
      count++;
    }
    return count;
  }

 private:
  std::deque<fml::closure> tasks_;
};

}  // namespace

TEST(PipelineCompileQueueVulkanTest, CreateSucceedsWithValidTaskRunner) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto queue = PipelineCompileQueueVulkan::Create(loop->GetTaskRunner());
  EXPECT_NE(queue, nullptr);
}

TEST(PipelineCompileQueueVulkanTest, PostJobDoesNothingWithNullClosure) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto queue = PipelineCompileQueueVulkan::Create(loop->GetTaskRunner());
  ASSERT_NE(queue, nullptr);

  queue->PostJob(nullptr);
}

TEST(PipelineCompileQueueVulkanTest, OnJobAddedProcessesJobsInParallel) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto queue = PipelineCompileQueueVulkan::Create(loop->GetTaskRunner());
  ASSERT_NE(queue, nullptr);

  std::atomic<int> concurrent_jobs{0};
  std::atomic<int> max_concurrent{0};
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
    int current = ++concurrent_jobs;
    int prev_max = max_concurrent.load();
    while (current > prev_max &&
           !max_concurrent.compare_exchange_weak(prev_max, current)) {
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    concurrent_jobs--;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc2, [&]() {
    int current = ++concurrent_jobs;
    int prev_max = max_concurrent.load();
    while (current > prev_max &&
           !max_concurrent.compare_exchange_weak(prev_max, current)) {
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    concurrent_jobs--;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc3, [&]() {
    int current = ++concurrent_jobs;
    int prev_max = max_concurrent.load();
    while (current > prev_max &&
           !max_concurrent.compare_exchange_weak(prev_max, current)) {
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    concurrent_jobs--;
    latch.CountDown();
  });

  latch.Wait();

  EXPECT_GE(max_concurrent.load(), 1);
}

TEST(PipelineCompileQueueVulkanTest,
     PostJobForDescriptorWithDuplicateRunsEagerly) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto queue = PipelineCompileQueueVulkan::Create(loop->GetTaskRunner());
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
}

TEST(PipelineCompileQueueVulkanTest, MultipleJobsCompleteSuccessfully) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto queue = PipelineCompileQueueVulkan::Create(loop->GetTaskRunner());
  ASSERT_NE(queue, nullptr);

  std::atomic<int> completed_jobs{0};
  fml::CountDownLatch latch(5);

  PipelineDescriptor desc1;
  desc1.SetSampleCount(SampleCount::kCount1);
  desc1.SetCullMode(CullMode::kNone);

  PipelineDescriptor desc2;
  desc2.SetSampleCount(SampleCount::kCount1);
  desc2.SetCullMode(CullMode::kFrontFace);

  PipelineDescriptor desc3;
  desc3.SetSampleCount(SampleCount::kCount1);
  desc3.SetCullMode(CullMode::kBackFace);

  PipelineDescriptor desc4;
  desc4.SetSampleCount(SampleCount::kCount4);
  desc4.SetCullMode(CullMode::kNone);

  PipelineDescriptor desc5;
  desc5.SetSampleCount(SampleCount::kCount4);
  desc5.SetCullMode(CullMode::kFrontFace);

  // Post 5 jobs with distinct descriptors
  queue->PostJobForDescriptor(desc1, [&]() {
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc2, [&]() {
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc3, [&]() {
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc4, [&]() {
    completed_jobs++;
    latch.CountDown();
  });

  queue->PostJobForDescriptor(desc5, [&]() {
    completed_jobs++;
    latch.CountDown();
  });

  latch.Wait();

  EXPECT_EQ(completed_jobs, 5);
}

TEST(PipelineCompileQueueVulkanTest, PostJobForDescriptorRejectsNullJob) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueVulkan::Create(runner);
  ASSERT_NE(queue, nullptr);

  EXPECT_FALSE(queue->PostJobForDescriptor(PipelineDescriptor{}, nullptr));
  EXPECT_EQ(runner->RunAll(), 0u);
}

TEST(PipelineCompileQueueVulkanTest, PerformJobEagerlyExecutesPendingJob) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueVulkan::Create(runner);
  ASSERT_NE(queue, nullptr);

  PipelineDescriptor desc;
  int executed = 0;
  ASSERT_TRUE(queue->PostJobForDescriptor(desc, [&executed] { executed++; }));
  EXPECT_EQ(executed, 0);

  queue->PerformJobEagerly(desc);
  EXPECT_EQ(executed, 1);

  // The posted worker task must not execute the job a second time.
  runner->RunAll();
  EXPECT_EQ(executed, 1);
}

TEST(PipelineCompileQueueVulkanTest,
     PerformJobEagerlyIgnoresUnknownDescriptor) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueVulkan::Create(runner);
  ASSERT_NE(queue, nullptr);

  queue->PerformJobEagerly(PipelineDescriptor{});
  EXPECT_EQ(runner->RunAll(), 0u);
}

TEST(PipelineCompileQueueVulkanTest, ExecutesJobsInInsertionOrder) {
  constexpr size_t kJobCount = 10;
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueVulkan::Create(runner);
  ASSERT_NE(queue, nullptr);

  std::vector<size_t> job_order;
  for (size_t i = 0; i < kJobCount; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->PostJobForDescriptor(
        desc, [&job_order, index = i] { job_order.push_back(index); }));
  }

  runner->RunAll();

  ASSERT_EQ(job_order.size(), kJobCount);
  for (size_t i = 0; i < kJobCount; i++) {
    EXPECT_EQ(i, job_order[i]);
  }
}

TEST(PipelineCompileQueueVulkanTest, DestructorFinishesPendingJobs) {
  auto runner = std::make_shared<CapturingTaskRunner>();
  auto queue = PipelineCompileQueueVulkan::Create(runner);
  ASSERT_NE(queue, nullptr);

  int executed = 0;
  ASSERT_TRUE(queue->PostJobForDescriptor(PipelineDescriptor{},
                                          [&executed] { executed++; }));
  EXPECT_EQ(executed, 0);

  queue.reset();
  EXPECT_EQ(executed, 1);

  // Outstanding tasks hold a weak reference and must be no-ops now.
  runner->RunAll();
  EXPECT_EQ(executed, 1);
}

}  // namespace testing
}  // namespace impeller
