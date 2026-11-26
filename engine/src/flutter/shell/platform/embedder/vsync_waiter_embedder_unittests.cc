// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

#include <atomic>
#include <thread>
#include <vector>

#include "flutter/fml/message_loop_impl.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace flutter {
namespace {
template <typename T>
struct CountingAllocator {
  using value_type = T;
  std::atomic<int>* blocks;
  explicit CountingAllocator(std::atomic<int>* count) : blocks(count) {}
  template <typename U>
  CountingAllocator(const CountingAllocator<U>& other) : blocks(other.blocks) {}
  T* allocate(size_t count) {
    ++*blocks;
    return std::allocator<T>{}.allocate(count);
  }
  void deallocate(T* pointer, size_t count) {
    --*blocks;
    std::allocator<T>{}.deallocate(pointer, count);
  }
};

class QueuedRunner : public fml::TaskRunner {
 public:
  QueuedRunner() : TaskRunner(nullptr) {}
  void PostTask(const fml::closure& task) override { tasks.push_back(task); }
  void PostTaskForTime(const fml::closure& task, fml::TimePoint) override {
    tasks.push_back(task);
  }
  bool RunsTasksOnCurrentThread() override { return true; }
  fml::TaskQueueId GetTaskQueueId() override {
    return fml::TaskQueueId(fml::TaskQueueId::kInvalid);
  }
  void Drain() {
    while (!tasks.empty()) {
      auto pending = std::move(tasks);
      tasks.clear();
      for (auto& task : pending) {
        task();
      }
    }
  }
  std::vector<fml::closure> tasks;
};

class VsyncWaiterEmbedderTest : public ::testing::Test {
 protected:
  fml::RefPtr<QueuedRunner> runner = fml::MakeRefCounted<QueuedRunner>();
  TaskRunners runners{"test", runner, runner, runner, runner};
  std::atomic<int> allocation_blocks = 0;
  intptr_t baton = 0;
  int delivered = 0;
  std::shared_ptr<VsyncWaiterEmbedder> MakeWaiter() {
    auto waiter = std::allocate_shared<VsyncWaiterEmbedder>(
        CountingAllocator<VsyncWaiterEmbedder>(&allocation_blocks),
        [this](intptr_t value) { baton = value; }, runners);
    waiter->AsyncWaitForVsync([this](auto) { delivered++; });
    return waiter;
  }
  bool Deliver(intptr_t value) {
    auto now = fml::TimePoint::Now();
    return VsyncWaiterEmbedder::OnEmbedderVsync(
        runners, value, now, now + fml::TimeDelta::FromMilliseconds(16));
  }
};

TEST_F(VsyncWaiterEmbedderTest, OrdinaryDeliveryRejectsDuplicateToken) {
  auto waiter = MakeWaiter();
  EXPECT_TRUE(Deliver(baton));
  EXPECT_FALSE(Deliver(baton));
  runner->Drain();
  EXPECT_EQ(delivered, 1);
}

TEST_F(VsyncWaiterEmbedderTest, DestructionCancelsAndNeverRecyclesTokens) {
  auto waiter = MakeWaiter();
  const intptr_t old = baton;
  waiter.reset();
  EXPECT_EQ(allocation_blocks, 0);
  EXPECT_FALSE(Deliver(old));
  auto replacement = MakeWaiter();
  EXPECT_NE(baton, old);
  EXPECT_FALSE(Deliver(old));
  EXPECT_TRUE(Deliver(baton));
  runner->Drain();
  EXPECT_EQ(delivered, 1);
}

TEST_F(VsyncWaiterEmbedderTest, QueuedDeliveryDoesNotRetainWaiter) {
  auto waiter = MakeWaiter();
  EXPECT_TRUE(Deliver(baton));
  std::weak_ptr<VsyncWaiterEmbedder> weak = waiter;
  waiter.reset();
  EXPECT_TRUE(weak.expired());
  runner->Drain();
  EXPECT_EQ(delivered, 0);
}

TEST_F(VsyncWaiterEmbedderTest, DiscardedUiTaskReleasesBatonOwnership) {
  auto waiter = MakeWaiter();
  EXPECT_TRUE(Deliver(baton));
  waiter.reset();
  // Destroy the posted closure without executing it, as at thread shutdown.
  runner->tasks.clear();
  EXPECT_EQ(allocation_blocks, 0);
  EXPECT_FALSE(Deliver(baton));
  EXPECT_EQ(delivered, 0);
}

TEST_F(VsyncWaiterEmbedderTest, DeliveryCanRaceWaiterDestruction) {
  for (int i = 0; i < 100; ++i) {
    auto waiter = MakeWaiter();
    std::thread worker([&] { Deliver(baton); });
    waiter.reset();
    worker.join();
    runner->Drain();
    EXPECT_FALSE(Deliver(baton));
  }
  EXPECT_EQ(delivered, 0);
}
}  // namespace
}  // namespace flutter
