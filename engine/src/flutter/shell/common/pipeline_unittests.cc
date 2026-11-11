// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/pipeline.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <functional>
#include <future>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using IntPipeline = Pipeline<int>;
using Continuation = IntPipeline::ProducerContinuation;

TEST(PipelineTest, ConsumeOneVal) {
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(2);

  Continuation continuation = pipeline->Produce();

  const int test_val = 1;
  PipelineProduceResult result =
      continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);

  PipelineConsumeResult consume_result = pipeline->Consume(
      [&test_val](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val); });

  ASSERT_EQ(consume_result, PipelineConsumeResult::Done);
}

TEST(PipelineTest, ContinuationCanOnlyBeUsedOnce) {
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(2);

  Continuation continuation = pipeline->Produce();

  const int test_val = 1;
  PipelineProduceResult result =
      continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val); });

  result = continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(result.success, false);
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);

  PipelineConsumeResult consume_result_2 =
      pipeline->Consume([](std::unique_ptr<int> v) { FAIL(); });

  result = continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(result.success, false);
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::NoneAvailable);
}

TEST(PipelineTest, PushingMoreThanDepthCompletesFirstSubmission) {
  const int depth = 1;
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->Produce();

  const int test_val_1 = 1, test_val_2 = 2;
  PipelineProduceResult result =
      continuation_1.Complete(std::make_unique<int>(test_val_1));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);
  result = continuation_2.Complete(std::make_unique<int>(test_val_2));
  ASSERT_EQ(result.success, false);

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });

  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);
}

TEST(PipelineTest, PushingMultiProcessesInOrder) {
  const int depth = 2;
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->Produce();

  const int test_val_1 = 1, test_val_2 = 2;
  PipelineProduceResult result =
      continuation_1.Complete(std::make_unique<int>(test_val_1));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);
  result = continuation_2.Complete(std::make_unique<int>(test_val_2));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, false);

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::MoreAvailable);

  PipelineConsumeResult consume_result_2 = pipeline->Consume(
      [&test_val_2](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_2); });
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::Done);
}

TEST(PipelineTest, ProduceIfEmptyDoesNotConsumeWhenQueueIsNotEmpty) {
  const int depth = 2;
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->ProduceIfEmpty();

  const int test_val_1 = 1, test_val_2 = 2;
  PipelineProduceResult result =
      continuation_1.Complete(std::make_unique<int>(test_val_1));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);
  result = continuation_2.Complete(std::make_unique<int>(test_val_2));
  ASSERT_EQ(result.success, false);

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);
}

TEST(PipelineTest, ProduceIfEmptySuccessfulIfQueueIsEmpty) {
  const int depth = 1;
  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->ProduceIfEmpty();

  const int test_val_1 = 1;
  PipelineProduceResult result =
      continuation_1.Complete(std::make_unique<int>(test_val_1));
  ASSERT_EQ(result.success, true);
  ASSERT_EQ(result.is_first_item, true);

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);
}

TEST(PipelineTest, ConcurrentAnimatorAndRasterizerPatternDoesNotLoseWakeup) {
  constexpr int kTotalFrames = 10000;
  const unsigned int cores = std::thread::hardware_concurrency();
  const int kContenderThreads =
      cores > 0 ? (cores < 4 ? static_cast<int>(cores) : 4) : 2;

  std::shared_ptr<IntPipeline> pipeline = std::make_shared<IntPipeline>(2);

  std::mutex task_mutex;
  std::condition_variable task_cv;
  std::deque<std::function<void()>> raster_tasks;
  bool stop_raster = false;

  auto post_raster_task = [&](std::function<void()> task) {
    {
      std::scoped_lock lock(task_mutex);
      raster_tasks.push_back(std::move(task));
    }
    task_cv.notify_one();
  };

  std::atomic<bool> stop_contenders{false};
  std::vector<std::thread> contenders;
  contenders.reserve(kContenderThreads);
  for (int i = 0; i < kContenderThreads; ++i) {
    contenders.emplace_back([&stop_contenders]() {
      volatile uint64_t spin = 1;
      while (!stop_contenders.load(std::memory_order_relaxed)) {
        for (int j = 0; j < 64; ++j) {
          spin = spin * 6364136223846793005ULL + 1;
        }
        std::this_thread::yield();
      }
    });
  }

  std::atomic<int> consumed_count{0};
  std::atomic<bool> fifo_order_valid{true};
  int expected_frame = 1;
  std::mutex done_mutex;
  std::condition_variable done_cv;

  std::function<void()> raster_draw;
  raster_draw = [&]() {
    PipelineConsumeResult consume_result =
        pipeline->Consume([&](std::unique_ptr<int> v) {
          if (!v || *v != expected_frame) {
            fifo_order_valid.store(false, std::memory_order_relaxed);
          }
          ++expected_frame;
          if (consumed_count.fetch_add(1, std::memory_order_release) + 1 ==
              kTotalFrames) {
            std::scoped_lock lock(done_mutex);
            done_cv.notify_all();
          }
        });
    if (consume_result == PipelineConsumeResult::MoreAvailable) {
      post_raster_task(raster_draw);
    }
  };

  std::thread raster_thread([&]() {
    for (;;) {
      std::function<void()> task;
      {
        std::unique_lock lock(task_mutex);
        task_cv.wait(lock,
                     [&]() { return stop_raster || !raster_tasks.empty(); });
        if (!raster_tasks.empty()) {
          task = std::move(raster_tasks.front());
          raster_tasks.pop_front();
        } else if (stop_raster) {
          return;
        }
      }
      task();
    }
  });

  bool deadlocked = false;
  for (int frame = 1; frame <= kTotalFrames; ++frame) {
    Continuation continuation = pipeline->Produce();
    if (!continuation) {
      auto wait_start = std::chrono::steady_clock::now();
      while (!continuation) {
        std::this_thread::yield();
        continuation = pipeline->Produce();
        if (!continuation && std::chrono::steady_clock::now() - wait_start >
                                 std::chrono::seconds(5)) {
          deadlocked = true;
          break;
        }
      }
      if (deadlocked) {
        break;
      }
    }

    PipelineProduceResult result =
        continuation.Complete(std::make_unique<int>(frame));
    ASSERT_TRUE(result.success);
    if (result.is_first_item) {
      post_raster_task(raster_draw);
    }
  }

  if (!deadlocked) {
    std::unique_lock lock(done_mutex);
    deadlocked = !done_cv.wait_for(lock, std::chrono::seconds(10), [&]() {
      return consumed_count.load(std::memory_order_acquire) == kTotalFrames;
    });
  }

  stop_contenders.store(true, std::memory_order_relaxed);
  for (std::thread& contender : contenders) {
    contender.join();
  }
  {
    std::scoped_lock lock(task_mutex);
    stop_raster = true;
  }
  task_cv.notify_all();
  raster_thread.join();

  EXPECT_FALSE(deadlocked);
  EXPECT_TRUE(fifo_order_valid.load(std::memory_order_relaxed));
  EXPECT_EQ(consumed_count.load(std::memory_order_acquire), kTotalFrames);
}

}  // namespace testing
}  // namespace flutter
