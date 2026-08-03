// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include "gtest/gtest.h"

#include "fml/memory/ref_ptr.h"

namespace flutter::gpu {
namespace {

// Regression test for https://github.com/flutter/flutter/issues/188712:
// SetDepthWriteEnable must honor its argument. It previously ignored the
// argument and always enabled depth writes, so disabling depth writes (for
// example to keep overlapping translucent draws from self-occluding) had no
// effect.
TEST(FlutterGpuRenderPassTest, SetDepthWriteEnableHonorsArgument) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), true);
  EXPECT_TRUE(render_pass->GetDepthAttachmentDescriptor().depth_write_enabled);

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), false);
  EXPECT_FALSE(render_pass->GetDepthAttachmentDescriptor().depth_write_enabled);
}

// Draws memoize the built pipeline until the pipeline-affecting state
// changes, so every state mutation must mark the state dirty (a missed
// mutation would silently draw with a stale pipeline).
TEST(FlutterGpuRenderPassTest, PipelineStateMutationsMarkStateDirty) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  // A fresh pass must build a pipeline on first draw.
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), true);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  InternalFlutterGpu_RenderPass_SetColorBlendEnable(render_pass.get(), 0, true);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  InternalFlutterGpu_RenderPass_SetDepthCompareOperation(render_pass.get(), 0);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetPipeline(nullptr);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());
}

}  // namespace
}  // namespace flutter::gpu
