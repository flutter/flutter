// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

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

TEST(MockPipelineLibrary, LogPipelineCreationMarksPipelineWarmed) {
  MockPipelineLibrary pipeline_library;

  PipelineDescriptor warmed_desc;
  warmed_desc.SetLabel("warmed_pipeline");

  PipelineDescriptor unused_warmed_desc;
  unused_warmed_desc.SetLabel("unused_warmed_pipeline");

  PipelineDescriptor lazy_desc;
  lazy_desc.SetLabel("lazy_pipeline");

  pipeline_library.LogPipelineCreation(warmed_desc);
  pipeline_library.LogPipelineUsage(warmed_desc);
  pipeline_library.LogPipelineCreation(unused_warmed_desc);
  pipeline_library.LogPipelineUsage(lazy_desc);

  auto usage = pipeline_library.GetPipelineUsage();
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage.size(), 3u);
  EXPECT_EQ(usage[warmed_desc].count, 1);
  EXPECT_TRUE(usage[warmed_desc].warmed);
  // Warmed pipelines are reported even if they are never bound.
  EXPECT_EQ(usage[unused_warmed_desc].count, 0);
  EXPECT_TRUE(usage[unused_warmed_desc].warmed);
  EXPECT_EQ(usage[lazy_desc].count, 1);
  EXPECT_FALSE(usage[lazy_desc].warmed);
#else
  EXPECT_TRUE(usage.empty());
#endif
}

}  // namespace  testing
}  // namespace impeller
