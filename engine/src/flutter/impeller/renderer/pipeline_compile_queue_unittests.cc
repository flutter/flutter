// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_compile_queue.h"

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

class TestPipelineCompileQueue : public PipelineCompileQueue {
 public:
  void PostJob(const fml::closure& job) override {
    if (job) {
      job();
    }
  }

  void OnJobAdded() override {}

  bool AddJobForTest(const PipelineDescriptor& desc, const fml::closure& job) {
    return AddJob(desc, job);
  }

  bool HasPendingJobsForTest() { return HasPendingJobs(); }

  void DoOneJobForTest() { DoOneJob(); }
};

TEST(PipelineCompileQueueTest, AddJobReturnsTrueForNewDescriptor) {
  TestPipelineCompileQueue queue;
  PipelineDescriptor desc;
  bool job_executed = false;
  fml::closure job = [&job_executed]() { job_executed = true; };

  bool result = queue.AddJobForTest(desc, job);
  EXPECT_TRUE(result);
}

TEST(PipelineCompileQueueTest, AddJobReturnsFalseForDuplicateDescriptor) {
  TestPipelineCompileQueue queue;
  PipelineDescriptor desc;
  bool job1_executed = false;
  bool job2_executed = false;
  fml::closure job1 = [&job1_executed]() { job1_executed = true; };
  fml::closure job2 = [&job2_executed]() { job2_executed = true; };

  bool result1 = queue.AddJobForTest(desc, job1);
  bool result2 = queue.AddJobForTest(desc, job2);

  EXPECT_TRUE(result1);
  EXPECT_FALSE(result2);
}

TEST(PipelineCompileQueueTest, HasPendingJobsReturnsCorrectState) {
  TestPipelineCompileQueue queue;
  PipelineDescriptor desc;
  fml::closure job = []() {};

  EXPECT_FALSE(queue.HasPendingJobsForTest());

  queue.AddJobForTest(desc, job);
  EXPECT_TRUE(queue.HasPendingJobsForTest());
}

TEST(PipelineCompileQueueTest, PerformJobEagerlyExecutesJob) {
  TestPipelineCompileQueue queue;
  PipelineDescriptor desc;
  bool job_executed = false;
  fml::closure job = [&job_executed]() { job_executed = true; };

  queue.AddJobForTest(desc, job);
  queue.PerformJobEagerly(desc);

  EXPECT_TRUE(job_executed);
  EXPECT_FALSE(queue.HasPendingJobsForTest());
}

TEST(PipelineCompileQueueTest, FinishAllJobsDrainsQueue) {
  auto queue = std::make_shared<TestPipelineCompileQueue>();
  PipelineDescriptor desc;
  bool job_executed = false;
  fml::closure job = [&job_executed]() { job_executed = true; };

  queue->AddJobForTest(desc, job);
  EXPECT_TRUE(queue->HasPendingJobsForTest());

  queue.reset();

  EXPECT_TRUE(job_executed);
}

TEST(PipelineCompileQueueTest, ExecutesJobsInInsertionOrder) {
  constexpr size_t kJobCount = 10;
  auto queue = std::make_shared<TestPipelineCompileQueue>();

  std::vector<size_t> job_order;
  for (size_t i = 0; i < kJobCount; i++) {
    PipelineDescriptor desc;
    desc.SetLabel(std::to_string(i));
    ASSERT_TRUE(queue->AddJobForTest(
        desc, [&job_order, index = i] { job_order.push_back(index); }));
  }

  for (size_t i = 0; i < kJobCount; i++) {
    queue->DoOneJobForTest();
  }

  EXPECT_EQ(job_order.size(), kJobCount);
  for (size_t i = 0; i < kJobCount; i++) {
    EXPECT_EQ(i, job_order[i]);
  }
}

}  // namespace testing
}  // namespace impeller
