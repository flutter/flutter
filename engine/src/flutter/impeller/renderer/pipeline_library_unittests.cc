// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_use_counter.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

class TestPipeline : public Pipeline<PipelineDescriptor> {
 public:
  explicit TestPipeline(const PipelineDescriptor& desc)
      : Pipeline(std::weak_ptr<PipelineLibrary>(), desc) {}

  bool IsValid() const override { return true; }
};

TEST(MockPipelineLibrary, LogAndGetPipelineUsageSinglePipeline) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor pipeline_desc;
  pipeline_desc.SetLabel("pipeline");

  pipeline_library.LogPipelineUsage(pipeline_desc);
  pipeline_library.LogPipelineUsage(pipeline_desc);

  auto usage = pipeline_library.GetPipelineUsage();
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage[pipeline_desc].count, 2);
#else
  EXPECT_EQ(usage[pipeline_desc].count, 0);
#endif
}

TEST(MockPipelineLibrary, LogAndGetPipelineUsageMultiplePipelines) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor pipeline_a;
  pipeline_a.SetLabel("pipeline_a");

  PipelineDescriptor pipeline_b;
  pipeline_b.SetLabel("pipeline_b");

  pipeline_library.LogPipelineUsage(pipeline_a);
  pipeline_library.LogPipelineUsage(pipeline_a);
  pipeline_library.LogPipelineUsage(pipeline_b);

  auto usage = pipeline_library.GetPipelineUsage();

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage[pipeline_a].count, 2);
  EXPECT_EQ(usage[pipeline_b].count, 1);
#else
  EXPECT_EQ(usage[pipeline_a].count, 0);
  EXPECT_EQ(usage[pipeline_b].count, 0);
#endif
}

TEST(MockPipelineLibrary, LogPipelineCreationMarksPipelineEagerlyCreated) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor eager_desc;
  eager_desc.SetLabel("eager_pipeline");

  PipelineDescriptor unused_eager_desc;
  unused_eager_desc.SetLabel("unused_eager_pipeline");

  PipelineDescriptor lazy_desc;
  lazy_desc.SetLabel("lazy_pipeline");

  pipeline_library.LogPipelineCreation(eager_desc);
  pipeline_library.LogPipelineUsage(eager_desc);
  pipeline_library.LogPipelineCreation(unused_eager_desc);
  pipeline_library.LogPipelineUsage(lazy_desc);

  auto usage = pipeline_library.GetPipelineUsage();
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage.size(), 3u);
  EXPECT_EQ(usage[eager_desc].count, 1);
  EXPECT_TRUE(usage[eager_desc].eagerly_created);
  // Eagerly created pipelines are reported even if they are never bound.
  EXPECT_EQ(usage[unused_eager_desc].count, 0);
  EXPECT_TRUE(usage[unused_eager_desc].eagerly_created);
  EXPECT_EQ(usage[lazy_desc].count, 1);
  EXPECT_FALSE(usage[lazy_desc].eagerly_created);
#else
  EXPECT_TRUE(usage.empty());
#endif
}

// A pass reports its uses once per distinct pipeline when flushed, with the
// same totals as logging every use.
TEST(MockPipelineLibrary, PipelineUseCounterReportsTotalsOnFlush) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor desc_a;
  desc_a.SetLabel("pipeline_a");
  PipelineDescriptor desc_b;
  desc_b.SetLabel("pipeline_b");
  TestPipeline pipeline_a(desc_a);
  TestPipeline pipeline_b(desc_b);

  PipelineUseCounter counter;
  counter.Count(&pipeline_a);
  counter.Count(&pipeline_a);
  counter.Count(&pipeline_b);
  counter.Count(&pipeline_a);
  EXPECT_TRUE(pipeline_library.GetPipelineUsage().empty());

  counter.Flush(pipeline_library);
  counter.Flush(pipeline_library);
  auto usage = pipeline_library.GetPipelineUsage();

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage[desc_a].count, 3);
  EXPECT_EQ(usage[desc_b].count, 1);
#else
  EXPECT_EQ(usage[desc_a].count, 0);
  EXPECT_EQ(usage[desc_b].count, 0);
#endif
}

}  // namespace  testing
}  // namespace impeller
