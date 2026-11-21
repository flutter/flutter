// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_heap_profiler.h"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string_view>

#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/fixture_test.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace flutter::testing {
namespace {

struct DelegateCounters {
  std::atomic<size_t> vm_init_count{0};
  std::atomic<size_t> vm_cleanup_count{0};
  std::atomic<size_t> created_count{0};
  std::atomic<size_t> destroyed_count{0};
  std::atomic<size_t> total_bytes{0};
};

class TestHeapProfilerDelegate final : public DartHeapProfilerDelegate {
 public:
  explicit TestHeapProfilerDelegate(std::shared_ptr<DelegateCounters> counters)
      : counters_(std::move(counters)) {}

  void OnDartVMInitialized() override {
    counters_->vm_init_count.fetch_add(1, std::memory_order_relaxed);
  }

  void OnDartVMCleanup() override {
    counters_->vm_cleanup_count.fetch_add(1, std::memory_order_relaxed);
  }

  void* OnSampleCreated(uintptr_t isolate_group_id,
                        std::string_view class_name,
                        size_t size) override {
    if (isolate_group_id == 0 || class_name.empty() || size == 0) {
      return nullptr;
    }
    counters_->created_count.fetch_add(1, std::memory_order_relaxed);
    counters_->total_bytes.fetch_add(size, std::memory_order_relaxed);
    return new size_t(size);
  }

  void OnSampleDestroyed(void* sample_context) override {
    delete static_cast<size_t*>(sample_context);
    counters_->destroyed_count.fetch_add(1, std::memory_order_relaxed);
  }

 private:
  std::shared_ptr<DelegateCounters> counters_;
};

class DartHeapProfilerTest : public FixtureTest {
 protected:
  void TearDown() override {
    DartHeapProfiler::StopSampling();
    DartHeapProfiler::SetDelegate(nullptr);
    FixtureTest::TearDown();
  }
};

TEST_F(DartHeapProfilerTest, SamplesDartAllocationsAndNotifiesLifecycle) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto counters = std::make_shared<DelegateCounters>();
  DartHeapProfiler::SetDelegate(
      std::make_unique<TestHeapProfilerDelegate>(counters));
  // Request sampling before VM initialization to verify startup queuing.
  DartHeapProfiler::StartSampling(/*sampling_interval_bytes=*/1024);

  {
    const auto settings = CreateSettingsForFixture();
    auto vm_ref = DartVMRef::Create(settings);
    ASSERT_TRUE(vm_ref);
    EXPECT_EQ(counters->vm_init_count.load(), 1u);

    TaskRunners task_runners(GetCurrentTestName(), GetCurrentTaskRunner(),
                             GetCurrentTaskRunner(), GetCurrentTaskRunner(),
                             GetCurrentTaskRunner());
    auto isolate = RunDartCodeInIsolate(vm_ref, settings, task_runners, "sayHi",
                                        {}, GetDefaultKernelFilePath());
    ASSERT_TRUE(isolate);
    EXPECT_GT(counters->created_count.load(), 0u);
    EXPECT_GT(counters->total_bytes.load(), 0u);
  }

  EXPECT_EQ(counters->vm_cleanup_count.load(), 1u);
  EXPECT_EQ(counters->destroyed_count.load(), counters->created_count.load());
}

TEST_F(DartHeapProfilerTest, StopSamplingSuppressesNewCallbacks) {
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
  auto counters = std::make_shared<DelegateCounters>();
  DartHeapProfiler::SetDelegate(
      std::make_unique<TestHeapProfilerDelegate>(counters));
  DartHeapProfiler::StopSampling();

  {
    const auto settings = CreateSettingsForFixture();
    auto vm_ref = DartVMRef::Create(settings);
    ASSERT_TRUE(vm_ref);
    EXPECT_EQ(counters->vm_init_count.load(), 1u);

    TaskRunners task_runners(GetCurrentTestName(), GetCurrentTaskRunner(),
                             GetCurrentTaskRunner(), GetCurrentTaskRunner(),
                             GetCurrentTaskRunner());
    auto isolate = RunDartCodeInIsolate(vm_ref, settings, task_runners, "sayHi",
                                        {}, GetDefaultKernelFilePath());
    ASSERT_TRUE(isolate);
    EXPECT_EQ(counters->created_count.load(), 0u);
  }
  EXPECT_EQ(counters->vm_cleanup_count.load(), 1u);
}

}  // namespace
}  // namespace flutter::testing
