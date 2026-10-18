// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include "gtest/gtest.h"

#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"

namespace flutter::gpu {
namespace {

fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      /*uniform_structs=*/{}, /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
}

fml::RefPtr<RenderPipeline> MakeRenderPipeline() {
  auto vertex = MakeShader(impeller::ShaderStage::kVertex);
  auto fragment = MakeShader(impeller::ShaderStage::kFragment);
  return fml::MakeRefCounted<RenderPipeline>(vertex, fragment,
                                             vertex->CreateVertexDescriptor());
}

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
  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetWindingOrder(impeller::WindingOrder::kCounterClockwise);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetPrimitiveType(impeller::PrimitiveType::kTriangleStrip);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetPolygonMode(impeller::PolygonMode::kLine);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetPipeline(MakeRenderPipeline());
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());
}

// Callers re-send the same fixed-function state and rebind the same pipeline
// ahead of most draws. Dirtying on those redundant assignments would rebuild
// the pipeline for every draw and leave the memoization doing nothing.
TEST(FlutterGpuRenderPassTest, RedundantPipelineStateAssignmentsAreIgnored) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();
  auto pipeline = MakeRenderPipeline();

  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  render_pass->SetWindingOrder(impeller::WindingOrder::kCounterClockwise);
  render_pass->SetPrimitiveType(impeller::PrimitiveType::kTriangleStrip);
  render_pass->SetPolygonMode(impeller::PolygonMode::kLine);
  render_pass->SetPipeline(pipeline);

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  render_pass->SetWindingOrder(impeller::WindingOrder::kCounterClockwise);
  render_pass->SetPrimitiveType(impeller::PrimitiveType::kTriangleStrip);
  render_pass->SetPolygonMode(impeller::PolygonMode::kLine);
  render_pass->SetPipeline(pipeline);
  EXPECT_FALSE(render_pass->IsPipelineStateDirtyForTesting());

  // A real change still dirties.
  render_pass->SetCullMode(impeller::CullMode::kFrontFace);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());
}

// A set goes into a slot rather than onto a list, so rebinding it once per
// draw (the expected usage) must not accumulate bindings on the pass.
TEST(FlutterGpuRenderPassTest, BindSetReplacesTheSlotContents) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();
  auto first = fml::MakeRefCounted<BindingSet>();
  auto second = fml::MakeRefCounted<BindingSet>();

  render_pass->BindSet(0, first);
  render_pass->BindSet(0, first);
  EXPECT_EQ(render_pass->binding_sets[0].get(), first.get());

  render_pass->BindSet(0, second);
  EXPECT_EQ(render_pass->binding_sets[0].get(), second.get());

  render_pass->BindSet(1, first);
  EXPECT_EQ(render_pass->binding_sets[0].get(), second.get());
  EXPECT_EQ(render_pass->binding_sets[1].get(), first.get());

  // An out of range slot is dropped rather than corrupting a valid one.
  render_pass->BindSet(RenderPass::kMaxBindingSets, first);
  EXPECT_EQ(render_pass->binding_sets[0].get(), second.get());

  render_pass->ClearBindings();
  for (const auto& set : render_pass->binding_sets) {
    EXPECT_EQ(set.get(), nullptr);
  }
}

}  // namespace
}  // namespace flutter::gpu
