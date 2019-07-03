// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/shell/common/pipeline.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using IntPipeline = Pipeline<int>;
using Continuation = IntPipeline::ProducerContinuation;

TEST(PipelineTest, ConsumeOneVal) {
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(2);

  Continuation continuation = pipeline->Produce();

  const int test_val = 1;
  continuation.Complete(std::make_unique<int>(test_val));

  PipelineConsumeResult consume_result = pipeline->Consume(
      [&test_val](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val); });

  ASSERT_EQ(consume_result, PipelineConsumeResult::Done);
}

TEST(PipelineTest, ContinuationCanOnlyBeUsedOnce) {
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(2);

  Continuation continuation = pipeline->Produce();

  const int test_val = 1;
  continuation.Complete(std::make_unique<int>(test_val));

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val); });

  continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);

  PipelineConsumeResult consume_result_2 =
      pipeline->Consume([](std::unique_ptr<int> v) { FAIL(); });

  continuation.Complete(std::make_unique<int>(test_val));
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::NoneAvailable);
}

TEST(PipelineTest, PushingMoreThanDepthCompletesFirstSubmission) {
  const int depth = 1;
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->Produce();

  const int test_val_1 = 1, test_val_2 = 2;
  continuation_1.Complete(std::make_unique<int>(test_val_1));
  continuation_2.Complete(std::make_unique<int>(test_val_2));

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });

  ASSERT_EQ(consume_result_1, PipelineConsumeResult::Done);
}

TEST(PipelineTest, PushingMultiProcessesInOrder) {
  const int depth = 2;
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->Produce();

  const int test_val_1 = 1, test_val_2 = 2;
  continuation_1.Complete(std::make_unique<int>(test_val_1));
  continuation_2.Complete(std::make_unique<int>(test_val_2));

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::MoreAvailable);

  PipelineConsumeResult consume_result_2 = pipeline->Consume(
      [&test_val_2](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_2); });
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::Done);
}

TEST(PipelineTest, PushingToFrontOverridesOrder) {
  const int depth = 2;
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->ProduceToFront();

  const int test_val_1 = 1, test_val_2 = 2;
  continuation_1.Complete(std::make_unique<int>(test_val_1));
  continuation_2.Complete(std::make_unique<int>(test_val_2));

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_2](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_2); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::MoreAvailable);

  PipelineConsumeResult consume_result_2 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::Done);
}

TEST(PipelineTest, PushingToFrontDropsLastResource) {
  const int depth = 2;
  fml::RefPtr<IntPipeline> pipeline = fml::MakeRefCounted<IntPipeline>(depth);

  Continuation continuation_1 = pipeline->Produce();
  Continuation continuation_2 = pipeline->Produce();
  Continuation continuation_3 = pipeline->ProduceToFront();

  const int test_val_1 = 1, test_val_2 = 2, test_val_3 = 3;
  continuation_1.Complete(std::make_unique<int>(test_val_1));
  continuation_2.Complete(std::make_unique<int>(test_val_2));
  continuation_3.Complete(std::make_unique<int>(test_val_3));

  PipelineConsumeResult consume_result_1 = pipeline->Consume(
      [&test_val_3](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_3); });
  ASSERT_EQ(consume_result_1, PipelineConsumeResult::MoreAvailable);

  PipelineConsumeResult consume_result_2 = pipeline->Consume(
      [&test_val_1](std::unique_ptr<int> v) { ASSERT_EQ(*v, test_val_1); });
  ASSERT_EQ(consume_result_2, PipelineConsumeResult::Done);
}

}  // namespace testing
}  // namespace flutter
