// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

TEST(MockPipelineLibrary, LogAndGetPipelineUsageSingleVariant) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor base_pipeline;
  base_pipeline.SetLabel("base_pipeline");
  auto base_pipeline_ptr = std::make_shared<PipelineDescriptor>(base_pipeline);

  PipelineDescriptor variant_a;
  variant_a.SetLabel("variant_a");
  variant_a.SetBasePipeline(base_pipeline_ptr);

  pipeline_library.LogPipelineUsage(variant_a);
  pipeline_library.LogPipelineUsage(variant_a);

  auto usage_counts = pipeline_library.GetPipelineUseCounts();

  EXPECT_EQ(usage_counts[base_pipeline], 2);
}

TEST(MockPipelineLibrary, LogAndGetPipelineUsageMultipleVariants) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor base_pipeline;
  base_pipeline.SetLabel("base_pipeline");
  auto base_pipeline_ptr = std::make_shared<PipelineDescriptor>(base_pipeline);

  PipelineDescriptor variant_a;
  variant_a.SetLabel("variant_a");
  variant_a.SetBasePipeline(base_pipeline_ptr);

  PipelineDescriptor variant_b;
  variant_b.SetLabel("variant_b");
  variant_b.SetBasePipeline(base_pipeline_ptr);

  pipeline_library.LogPipelineUsage(variant_a);
  pipeline_library.LogPipelineUsage(variant_a);
  pipeline_library.LogPipelineUsage(variant_b);

  auto usage_counts = pipeline_library.GetPipelineUseCounts();

  EXPECT_EQ(usage_counts[base_pipeline], 3);
}

TEST(MockPipelineLibrary, LogAndGetPipelineUsageMultiplePipelinesAndVariants) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor base_pipeline_a;
  base_pipeline_a.SetLabel("base_pipeline_a");
  auto base_pipeline_a_ptr =
      std::make_shared<PipelineDescriptor>(base_pipeline_a);

  PipelineDescriptor variant_aa;
  variant_aa.SetLabel("variant_aa");
  variant_aa.SetBasePipeline(base_pipeline_a_ptr);

  PipelineDescriptor variant_ab;
  variant_ab.SetLabel("variant_ab");
  variant_ab.SetBasePipeline(base_pipeline_a_ptr);

  pipeline_library.LogPipelineUsage(variant_aa);
  pipeline_library.LogPipelineUsage(variant_aa);
  pipeline_library.LogPipelineUsage(variant_ab);

  PipelineDescriptor base_pipeline_b;
  base_pipeline_b.SetLabel("base_pipeline_b");
  auto base_pipeline_b_ptr =
      std::make_shared<PipelineDescriptor>(base_pipeline_b);

  PipelineDescriptor variant_ba;
  variant_ba.SetLabel("variant_ba");
  variant_ba.SetBasePipeline(base_pipeline_b_ptr);

  PipelineDescriptor variant_bb;
  variant_bb.SetLabel("variant_bb");
  variant_bb.SetBasePipeline(base_pipeline_b_ptr);

  pipeline_library.LogPipelineUsage(variant_ba);
  pipeline_library.LogPipelineUsage(variant_ba);
  pipeline_library.LogPipelineUsage(variant_bb);
  pipeline_library.LogPipelineUsage(variant_bb);

  auto usage_counts = pipeline_library.GetPipelineUseCounts();

  EXPECT_EQ(usage_counts[base_pipeline_a], 3);
  EXPECT_EQ(usage_counts[base_pipeline_b], 4);
}

}  // namespace  testing
}  // namespace impeller
