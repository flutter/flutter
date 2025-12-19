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

  auto usage_counts = pipeline_library.GetPipelineUseCounts();
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage_counts[pipeline_desc], 2);
#else
  EXPECT_EQ(usage_counts[pipeline_desc], 0);
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

  auto usage_counts = pipeline_library.GetPipelineUseCounts();

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  EXPECT_EQ(usage_counts[pipeline_a], 2);
  EXPECT_EQ(usage_counts[pipeline_b], 1);
#else
  EXPECT_EQ(usage_counts[pipeline_a], 0);
  EXPECT_EQ(usage_counts[pipeline_b], 0);
#endif
}

}  // namespace  testing
}  // namespace impeller
