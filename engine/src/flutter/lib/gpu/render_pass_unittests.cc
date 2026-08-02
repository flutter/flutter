// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/lib/gpu/command_buffer.h"
#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/render_pipeline.h"
#include "flutter/lib/gpu/shader.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockDeviceBuffer;
using ::impeller::testing::MockImpellerContext;
using ::impeller::testing::MockRenderPass;
using ::testing::_;
using ::testing::AnyNumber;
using ::testing::Return;

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

// A vertex-stage shader carrying two uniform structs. Enough to exercise the
// binding lists without a GPU context.
fml::RefPtr<Shader> MakeVertexShader() {
  std::unordered_map<std::string, Shader::UniformBinding> uniform_structs;
  uniform_structs.emplace(
      "FrameInfo",
      Shader::UniformBinding{
          .slot = {.name = "FrameInfo", .ext_res_0 = 0, .set = 0, .binding = 0},
          .metadata = {.name = "FrameInfo"},
          .size_in_bytes = 64,
      });
  uniform_structs.emplace(
      "JointInfo",
      Shader::UniformBinding{
          .slot = {.name = "JointInfo", .ext_res_0 = 1, .set = 0, .binding = 1},
          .metadata = {.name = "JointInfo"},
          .size_in_bytes = 64,
      });
  return Shader::Make("test_library", "vertex_main",
                      impeller::ShaderStage::kVertex, /*code_mapping=*/nullptr,
                      /*inputs=*/{}, /*layouts=*/{}, std::move(uniform_structs),
                      /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
}

fml::RefPtr<DeviceBuffer> MakeDeviceBuffer(size_t size_in_bytes) {
  impeller::DeviceBufferDescriptor desc;
  desc.size = size_in_bytes;
  return fml::MakeRefCounted<DeviceBuffer>(
      std::make_shared<MockDeviceBuffer>(desc));
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

// Draws bind the shader's own reflection metadata. Copying it per binding
// meant every draw allocated once for each bound uniform and texture.
TEST(FlutterGpuRenderPassTest, UniformBindingsBorrowShaderMetadata) {
  auto shader = MakeVertexShader();
  auto buffer = MakeDeviceBuffer(256);
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  const int index = shader->GetUniformStructIndex("FrameInfo");
  ASSERT_GE(index, 0);
  EXPECT_TRUE(InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
      render_pass.get(), shader.get(), index, buffer.get(),
      /*offset_in_bytes=*/0, /*length_in_bytes=*/64));

  ASSERT_EQ(render_pass->vertex_uniform_bindings.size(), 1u);
  const RenderPass::BufferAndUniformSlot& entry =
      render_pass->vertex_uniform_bindings[0];
  const Shader::UniformBinding* uniform = shader->GetUniformStruct("FrameInfo");
  EXPECT_EQ(entry.binding, uniform);
  EXPECT_EQ(entry.view.GetMetadata(), &uniform->metadata);
}

// A rebind must overwrite the existing entry instead of appending a second
// one, otherwise a pass that rebinds the same uniform per draw would grow its
// binding list without bound.
TEST(FlutterGpuRenderPassTest, RebindingAUniformOverwritesItInPlace) {
  auto shader = MakeVertexShader();
  auto buffer = MakeDeviceBuffer(256);
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  const int frame_info = shader->GetUniformStructIndex("FrameInfo");
  const int joint_info = shader->GetUniformStructIndex("JointInfo");
  ASSERT_GE(frame_info, 0);
  ASSERT_GE(joint_info, 0);

  EXPECT_TRUE(InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
      render_pass.get(), shader.get(), frame_info, buffer.get(), 0, 64));
  EXPECT_TRUE(InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
      render_pass.get(), shader.get(), joint_info, buffer.get(), 64, 64));
  EXPECT_TRUE(InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
      render_pass.get(), shader.get(), frame_info, buffer.get(), 128, 64));

  ASSERT_EQ(render_pass->vertex_uniform_bindings.size(), 2u);
  EXPECT_EQ(render_pass->vertex_uniform_bindings[0].binding,
            shader->GetUniformStruct("FrameInfo"));
  EXPECT_EQ(render_pass->vertex_uniform_bindings[1].binding,
            shader->GetUniformStruct("JointInfo"));
  EXPECT_EQ(
      render_pass->vertex_uniform_bindings[0].view.resource.GetRange().offset,
      128u);
}

// Bindings point at metadata owned by the shader, so the pass has to keep
// that shader alive. Clearing bindings must not release it either; draws
// already recorded still reference the metadata.
TEST(FlutterGpuRenderPassTest, BindingRetainsTheShaderOwningTheMetadata) {
  auto shader = MakeVertexShader();
  auto buffer = MakeDeviceBuffer(256);
  const int index = shader->GetUniformStructIndex("FrameInfo");
  ASSERT_GE(index, 0);

  {
    auto render_pass = fml::MakeRefCounted<RenderPass>();
    EXPECT_TRUE(shader->HasOneRef());

    EXPECT_TRUE(InternalFlutterGpu_RenderPass_BindUniformDeviceIndexed(
        render_pass.get(), shader.get(), index, buffer.get(), 0, 64));
    EXPECT_FALSE(shader->HasOneRef());

    render_pass->ClearBindings();
    EXPECT_TRUE(render_pass->vertex_uniform_bindings.empty());
    EXPECT_FALSE(shader->HasOneRef());
  }

  EXPECT_TRUE(shader->HasOneRef());
}

// Encoding happens at submit, after the last draw, and reads the borrowed
// metadata. The command buffer therefore has to keep the pass wrapper the
// bindings live on alive.
TEST(FlutterGpuRenderPassTest, CommandBufferRetainsTheRecordingPass) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto impeller_render_pass =
      std::make_shared<MockRenderPass>(context, impeller::RenderTarget());
  EXPECT_CALL(*impeller_render_pass, IsValid).WillRepeatedly(Return(true));
  EXPECT_CALL(*impeller_render_pass, OnSetLabel(_)).Times(AnyNumber());
  EXPECT_CALL(*impeller_command_buffer, OnCreateRenderPass(_))
      .WillOnce(Return(impeller_render_pass));

  CommandBuffer command_buffer(context, impeller_command_buffer);
  auto render_pass = fml::MakeRefCounted<RenderPass>();
  EXPECT_TRUE(render_pass->HasOneRef());

  EXPECT_TRUE(render_pass->Begin(command_buffer));
  EXPECT_FALSE(render_pass->HasOneRef());
}

}  // namespace
}  // namespace flutter::gpu
