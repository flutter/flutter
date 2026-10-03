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

  bool AddJobForTest(const PipelineDescriptor& desc,
                     const fml::closure& job,
                     Priority priority) {
    return AddJob(desc, job, priority);
  }

  bool HasPendingJobsForTest() { return HasPendingJobs(); }

  void DoOneJobForTest() { DoOneJob(); }
};

// Returns a descriptor that is unique with respect to ComparableHash and
// ComparableEqual, which key off the label among other things.
static PipelineDescriptor MakeDescriptor(const std::string& label,
                                         bool high_priority = false) {
  PipelineDescriptor desc;
  desc.SetLabel(label);
  desc.SetHighPriority(high_priority);
  return desc;
}

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

TEST(PipelineCompileQueueTest, HighPriorityJobsAreExecutedFirst) {
  auto queue = std::make_shared<TestPipelineCompileQueue>();

  std::vector<std::string> job_order;
  auto record = [&job_order](const std::string& name) {
    return [&job_order, name] { job_order.push_back(name); };
  };

  // Insert normal priority jobs first so that ordering can only be explained
  // by priority, not by insertion order.
  ASSERT_TRUE(queue->AddJobForTest(MakeDescriptor("normal0"), record("normal0"),
                                   PipelineCompileQueue::Priority::kNormal));
  ASSERT_TRUE(queue->AddJobForTest(MakeDescriptor("normal1"), record("normal1"),
                                   PipelineCompileQueue::Priority::kNormal));
  ASSERT_TRUE(queue->AddJobForTest(MakeDescriptor("high0"), record("high0"),
                                   PipelineCompileQueue::Priority::kHigh));
  ASSERT_TRUE(queue->AddJobForTest(MakeDescriptor("high1"), record("high1"),
                                   PipelineCompileQueue::Priority::kHigh));

  for (size_t i = 0; i < 4u; i++) {
    queue->DoOneJobForTest();
  }

  // High priority jobs first, and insertion order preserved within each class.
  EXPECT_EQ(job_order,
            (std::vector<std::string>{"high0", "high1", "normal0", "normal1"}));
}

TEST(PipelineCompileQueueTest, AddJobRejectsDuplicatesAcrossPriorities) {
  TestPipelineCompileQueue queue;
  // Priority is deliberately excluded from a descriptor's identity, so these
  // two descriptors are the same key.
  PipelineDescriptor normal_desc = MakeDescriptor("shared", false);
  PipelineDescriptor high_desc = MakeDescriptor("shared", true);

  EXPECT_TRUE(queue.AddJobForTest(
      normal_desc, [] {}, PipelineCompileQueue::Priority::kNormal));
  // Must be rejected even though it targets the other queue. Allowing this
  // would fulfill the same promise twice.
  EXPECT_FALSE(queue.AddJobForTest(
      high_desc, [] {}, PipelineCompileQueue::Priority::kHigh));

  // And the reverse direction.
  TestPipelineCompileQueue other_queue;
  EXPECT_TRUE(other_queue.AddJobForTest(
      high_desc, [] {}, PipelineCompileQueue::Priority::kHigh));
  EXPECT_FALSE(other_queue.AddJobForTest(
      normal_desc, [] {}, PipelineCompileQueue::Priority::kNormal));
}

TEST(PipelineCompileQueueTest, FinishAllJobsDrainsHighPriorityJobs) {
  auto queue = std::make_shared<TestPipelineCompileQueue>();
  bool high_executed = false;
  bool normal_executed = false;

  queue->AddJobForTest(
      MakeDescriptor("high"), [&high_executed] { high_executed = true; },
      PipelineCompileQueue::Priority::kHigh);
  queue->AddJobForTest(
      MakeDescriptor("normal"), [&normal_executed] { normal_executed = true; },
      PipelineCompileQueue::Priority::kNormal);

  // Destruction must drain both queues. A job left behind would leave its
  // promise unfulfilled and hang any thread that later waits on it.
  queue.reset();

  EXPECT_TRUE(high_executed);
  EXPECT_TRUE(normal_executed);
}

TEST(PipelineCompileQueueTest, HasPendingJobsSeesHighPriorityJobs) {
  TestPipelineCompileQueue queue;
  EXPECT_FALSE(queue.HasPendingJobsForTest());

  queue.AddJobForTest(
      MakeDescriptor("high"), [] {}, PipelineCompileQueue::Priority::kHigh);
  EXPECT_TRUE(queue.HasPendingJobsForTest());

  queue.DoOneJobForTest();
  EXPECT_FALSE(queue.HasPendingJobsForTest());
}

TEST(PipelineCompileQueueTest, PerformJobEagerlyTakesHighPriorityJobs) {
  TestPipelineCompileQueue queue;
  PipelineDescriptor desc = MakeDescriptor("high", true);
  bool job_executed = false;

  queue.AddJobForTest(
      desc, [&job_executed] { job_executed = true; },
      PipelineCompileQueue::Priority::kHigh);
  queue.PerformJobEagerly(desc);

  EXPECT_TRUE(job_executed);
  EXPECT_FALSE(queue.HasPendingJobsForTest());
}

}  // namespace testing
}  // namespace impeller
