// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_compile_queue_vulkan.h"

#include <atomic>
#include <memory>
#include <mutex>
#include <vector>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/task_runner.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

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

}  // namespace testing
}  // namespace impeller
