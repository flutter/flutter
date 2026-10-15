// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/lib/gpu/binding_set.h"
#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/base/validation.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      /*uniform_structs=*/{}, /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
}

// A shader declaring one uniform struct, "FrameInfo".
fml::RefPtr<Shader> MakeShaderWithUniform(impeller::ShaderStage stage) {
  std::unordered_map<std::string, Shader::UniformBinding> uniform_structs;
  uniform_structs["FrameInfo"] = Shader::UniformBinding{
      .slot = impeller::ShaderUniformSlot{.name = "FrameInfo"},
      .metadata = impeller::ShaderMetadata{.name = "FrameInfo", .members = {}},
      .size_in_bytes = 64,
  };
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      std::move(uniform_structs), /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
}

// A pass with a single color attachment, begun on [command_buffer].
fml::RefPtr<RenderPass> MakeBegunRenderPass(CommandBuffer& command_buffer) {
  impeller::TextureDescriptor desc;
  desc.size = impeller::ISize{1, 1};
  desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  auto texture =
      std::make_shared<::testing::NiceMock<impeller::testing::MockTexture>>(
          desc);
  ON_CALL(*texture, IsValid).WillByDefault(::testing::Return(true));
  ON_CALL(*texture, GetSize).WillByDefault(::testing::Return(desc.size));
  impeller::ColorAttachment color;
  color.texture = texture;
  color.load_action = impeller::LoadAction::kClear;
  color.store_action = impeller::StoreAction::kStore;

  auto render_pass = fml::MakeRefCounted<RenderPass>();
  render_pass->GetRenderTarget().SetColorAttachment(color, 0);
  EXPECT_TRUE(render_pass->Begin(command_buffer));
  return render_pass;
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

// Draws record against a snapshot of the pipeline state taken when the state
// was last dirtied, so consecutive draws share one snapshot.
TEST(FlutterGpuRenderPassTest, DrawsRecordAgainstPipelineStateSnapshots) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);
  render_pass->SetPipeline(MakeRenderPipeline());

  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  // No index buffer bound.
  EXPECT_FALSE(render_pass->Draw(3, 1, /*indexed=*/true));

  const auto& recording = render_pass->GetRecordingForTesting();
  EXPECT_EQ(recording.pipeline_states.size(), 2u);
  ASSERT_EQ(recording.draws.size(), 3u);
  EXPECT_EQ(recording.draws[0].pipeline_state, 0u);
  EXPECT_EQ(recording.draws[1].pipeline_state, 0u);
  EXPECT_EQ(recording.draws[2].pipeline_state, 1u);
}

// Once the command buffer is submitted its recording belongs to the replay
// thread, so the pass must not record anything more into it.
TEST(FlutterGpuRenderPassTest, SubmittedPassesRecordNothing) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);
  render_pass->SetPipeline(MakeRenderPipeline());
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));

  {
    // The mock context makes no command buffer, so the inline replay fails.
    impeller::ScopedValidationDisable disable_validation;
    command_buffer.Submit();
  }

  EXPECT_TRUE(render_pass->GetRecordingForTesting().sealed);
  EXPECT_FALSE(render_pass->Draw(3, 1, /*indexed=*/false));
  EXPECT_EQ(render_pass->GetRecordingForTesting().draws.size(), 1u);
  EXPECT_FALSE(
      command_buffer.AddRenderPass(std::make_shared<RenderPassRecording>()));
}

// A build failure is only discovered at replay. Later draws with the same
// state must fail when recorded, so the caller sees the failure.
TEST(FlutterGpuRenderPassTest, KnownBuildFailuresFailDrawsWhenRecorded) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  auto pipeline = MakeRenderPipeline();

  CommandBuffer first_buffer(context);
  auto first = MakeBegunRenderPass(first_buffer);
  first->SetPipeline(pipeline);
  EXPECT_TRUE(first->Draw(3, 1, /*indexed=*/false));
  pipeline->GetCore()->MarkBuildFailed(
      first->GetRecordingForTesting().pipeline_states[0].key);

  CommandBuffer second_buffer(context);
  auto second = MakeBegunRenderPass(second_buffer);
  second->SetPipeline(pipeline);
  EXPECT_FALSE(second->Draw(3, 1, /*indexed=*/false));
  EXPECT_TRUE(second->GetRecordingForTesting().draws.empty());

  // Different state is unaffected.
  second->SetCullMode(impeller::CullMode::kFrontFace);
  EXPECT_TRUE(second->Draw(3, 1, /*indexed=*/false));
}

// A shader reload swaps the reflection a recorded binding points into. The
// recording keeps the old reflection alive so the binding stays valid until
// replay.
TEST(FlutterGpuRenderPassTest, RecordingRetainsReflectionAcrossReload) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);

  auto shader = MakeShaderWithUniform(impeller::ShaderStage::kVertex);
  impeller::DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = 128;
  auto buffer =
      std::make_shared<impeller::testing::MockDeviceBuffer>(buffer_desc);
  ASSERT_TRUE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                       buffer, 0, 64));
  // Out of bounds views fail when recorded.
  EXPECT_FALSE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                        buffer, 100, 64));

  auto recorded_reflection = shader->GetReflection();
  auto reloaded = MakeShaderWithUniform(impeller::ShaderStage::kVertex);
  shader->ResetFrom(*reloaded);
  EXPECT_NE(shader->GetReflection(), recorded_reflection);

  const auto& recording = render_pass->GetRecordingForTesting();
  ASSERT_EQ(recording.reflections.size(), 1u);
  EXPECT_EQ(recording.reflections[0], recorded_reflection);
  ASSERT_EQ(recording.uniforms.size(), 1u);
  EXPECT_EQ(recording.uniforms[0].binding->metadata.name, "FrameInfo");
}

}  // namespace
}  // namespace flutter::gpu
