// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include <limits>

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

fml::RefPtr<DeviceBuffer> MakeDeviceBuffer(size_t size) {
  impeller::DeviceBufferDescriptor desc;
  desc.size = size;
  return fml::MakeRefCounted<DeviceBuffer>(
      std::make_shared<impeller::testing::MockDeviceBuffer>(desc));
}

size_t CountOps(const RenderPass& render_pass, RecordedOp kind) {
  size_t count = 0;
  render_pass.GetRecordingForTesting()->ops.ForEach(
      [&](const OpHeader& header) { count += header.op == kind ? 1 : 0; });
  return count;
}

// Regression test for https://github.com/flutter/flutter/issues/188712:
// SetDepthWriteEnable must honor its argument. It previously ignored the
// argument and always enabled depth writes, so disabling depth writes (for
// example to keep overlapping translucent draws from self-occluding) had no
// effect.
TEST(FlutterGpuRenderPassTest, SetDepthWriteEnableHonorsArgument) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), true);
  EXPECT_TRUE(render_pass->GetPipelineState().depth.depth_write_enabled);

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), false);
  EXPECT_FALSE(render_pass->GetPipelineState().depth.depth_write_enabled);
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
  auto pipeline = MakeRenderPipeline();
  render_pass->SetPipeline(pipeline.get());
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
  render_pass->SetPipeline(pipeline.get());

  render_pass->ClearPipelineStateDirtyForTesting();
  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  render_pass->SetWindingOrder(impeller::WindingOrder::kCounterClockwise);
  render_pass->SetPrimitiveType(impeller::PrimitiveType::kTriangleStrip);
  render_pass->SetPolygonMode(impeller::PolygonMode::kLine);
  render_pass->SetPipeline(pipeline.get());
  InternalFlutterGpu_RenderPass_SetColorBlendEnable(render_pass.get(), 0,
                                                    false);
  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), false);
  EXPECT_FALSE(render_pass->IsPipelineStateDirtyForTesting());

  // A real change still dirties.
  render_pass->SetCullMode(impeller::CullMode::kFrontFace);
  EXPECT_TRUE(render_pass->IsPipelineStateDirtyForTesting());
}

// Draws record the pipeline state when it was last dirtied, so consecutive
// draws share one record.
TEST(FlutterGpuRenderPassTest, DrawsRecordPipelineStateOnlyWhenItChanges) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);
  auto pipeline = MakeRenderPipeline();
  render_pass->SetPipeline(pipeline.get());

  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  render_pass->SetCullMode(impeller::CullMode::kBackFace);
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));
  // No index buffer bound.
  EXPECT_FALSE(render_pass->Draw(3, 1, /*indexed=*/true));

  EXPECT_EQ(CountOps(*render_pass, RecordedOp::kSetPipelineState), 2u);
  EXPECT_EQ(CountOps(*render_pass, RecordedOp::kDraw), 3u);
}

// Once a pass ends its recording belongs to the replay thread, so the pass
// must not record anything more into it.
TEST(FlutterGpuRenderPassTest, EndedPassesRecordNothing) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);
  auto pipeline = MakeRenderPipeline();
  render_pass->SetPipeline(pipeline.get());
  EXPECT_TRUE(render_pass->Draw(3, 1, /*indexed=*/false));

  {
    // The mock context makes no command buffer, so the inline replay fails.
    impeller::ScopedValidationDisable disable_validation;
    render_pass->End();
  }

  EXPECT_EQ(render_pass->GetRecordingForTesting(), nullptr);
  EXPECT_FALSE(render_pass->Draw(3, 1, /*indexed=*/false));
}

// A later command ends the open pass without telling the pass.
TEST(FlutterGpuRenderPassTest, PassesEndedByALaterPassRecordNothing) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto first = MakeBegunRenderPass(command_buffer);
  auto pipeline = MakeRenderPipeline();
  first->SetPipeline(pipeline.get());

  impeller::ScopedValidationDisable disable_validation;
  auto second = MakeBegunRenderPass(command_buffer);

  EXPECT_EQ(first->GetRecordingForTesting(), nullptr);
  EXPECT_FALSE(first->Draw(3, 1, /*indexed=*/false));
  EXPECT_NE(second->GetRecordingForTesting(), nullptr);
}

TEST(FlutterGpuRenderPassTest, ViewsMustFitTheirBuffer) {
  auto context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  CommandBuffer command_buffer(context);
  auto render_pass = MakeBegunRenderPass(command_buffer);
  auto shader = MakeShaderWithUniform(impeller::ShaderStage::kVertex);
  auto buffer = MakeDeviceBuffer(128);

  EXPECT_TRUE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                       *buffer, 64, 64));
  EXPECT_FALSE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                        *buffer, 100, 64));
  // A sum that overflows must not pass the bounds check.
  EXPECT_FALSE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                        *buffer, 64,
                                        std::numeric_limits<size_t>::max()));

  render_pass->BindVertexBuffer(0, *buffer, 64, 64);
  render_pass->BindVertexBuffer(0, *buffer, 100, 64);
  render_pass->BindIndexBuffer(*buffer, 100, 64, impeller::IndexType::k16bit);
  EXPECT_EQ(CountOps(*render_pass, RecordedOp::kBindVertexBuffer), 1u);
  EXPECT_EQ(CountOps(*render_pass, RecordedOp::kBindIndexBuffer), 0u);
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
  auto buffer = MakeDeviceBuffer(128);
  ASSERT_TRUE(render_pass->BindUniform(*shader, shader->GetUniformStructAt(0),
                                       *buffer, 0, 64));

  std::weak_ptr<const Shader::Reflection> recorded = shader->GetReflection();
  auto reloaded = MakeShaderWithUniform(impeller::ShaderStage::kVertex);
  shader->ResetFrom(*reloaded);
  EXPECT_NE(shader->GetReflection(), recorded.lock());
  EXPECT_FALSE(recorded.expired());

  {
    // The mock context makes no command buffer, so the inline replay fails
    // and nothing else holds the recording.
    impeller::ScopedValidationDisable disable_validation;
    render_pass->End();
    command_buffer.Submit();
  }
  EXPECT_TRUE(recorded.expired());
}

}  // namespace
}  // namespace flutter::gpu
