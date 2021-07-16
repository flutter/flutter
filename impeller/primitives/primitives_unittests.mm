// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "impeller/compositor/command.h"
#include "impeller/compositor/pipeline_builder.h"
#include "impeller/compositor/renderer.h"
#include "impeller/compositor/sampler_descriptor.h"
#include "impeller/compositor/surface.h"
#include "impeller/compositor/vertex_buffer_builder.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/image.h"
#include "impeller/playground/playground.h"
#include "impeller/primitives/box.frag.h"
#include "impeller/primitives/box.vert.h"

namespace impeller {
namespace testing {

using PrimitivesTest = Playground;

TEST_F(PrimitivesTest, CanCreateBoxPrimitive) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder =
      PipelineBuilder<BoxVertexShader, BoxFragmentShader>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  auto box_pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  ASSERT_TRUE(box_pipeline);

  // Vertex buffer.
  VertexBufferBuilder<BoxVertexShader::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  vertex_builder.AddVertices({
      {{100, 100, 0.0}, {0.0, 0.0}},  // 1
      {{800, 100, 0.0}, {1.0, 0.0}},  // 2
      {{800, 800, 0.0}, {1.0, 1.0}},  // 3
      {{100, 100, 0.0}, {0.0, 0.0}},  // 1
      {{800, 800, 0.0}, {1.0, 1.0}},  // 3
      {{100, 800, 0.0}, {0.0, 1.0}},  // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetPermanentsAllocator());
  ASSERT_TRUE(vertex_buffer);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);
  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    BoxVertexShader::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize());
    BoxVertexShader::BindUniformBuffer(
        cmd, pass.GetTransientsBuffer().EmplaceUniform(uniforms));

    BoxFragmentShader::FrameInfo frame_info;
    frame_info.current_time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    BoxFragmentShader::BindFrameInfo(
        cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    BoxFragmentShader::BindContents1(cmd, boston, sampler);
    BoxFragmentShader::BindContents2(cmd, bridge, sampler);

    cmd.primitive_type = PrimitiveType::kTriangle;
    if (!pass.RecordCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  // OpenPlaygroundHere(callback);
}

TEST_F(PrimitivesTest, CanRenderMultiplePrimitives) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder =
      PipelineBuilder<BoxVertexShader, BoxFragmentShader>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  auto box_pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  ASSERT_TRUE(box_pipeline);

  // Vertex buffer.
  VertexBufferBuilder<BoxVertexShader::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  vertex_builder.AddVertices({
      {{100, 100, 0.0}, {0.0, 0.0}},  // 1
      {{800, 100, 0.0}, {1.0, 0.0}},  // 2
      {{800, 800, 0.0}, {1.0, 1.0}},  // 3
      {{100, 100, 0.0}, {0.0, 0.0}},  // 1
      {{800, 800, 0.0}, {1.0, 1.0}},  // 3
      {{100, 800, 0.0}, {0.0, 1.0}},  // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetPermanentsAllocator());
  ASSERT_TRUE(vertex_buffer);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    BoxFragmentShader::FrameInfo frame_info;
    frame_info.current_time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    BoxFragmentShader::BindFrameInfo(
        cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    BoxFragmentShader::BindContents1(cmd, boston, sampler);
    BoxFragmentShader::BindContents2(cmd, bridge, sampler);

    cmd.primitive_type = PrimitiveType::kTriangle;

    {
      BoxVertexShader::UniformBuffer uniforms;
      uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize());
      BoxVertexShader::BindUniformBuffer(
          cmd, pass.GetTransientsBuffer().EmplaceUniform(uniforms));

      if (!pass.RecordCommand(cmd)) {
        return false;
      }
    }

    {
      BoxVertexShader::UniformBuffer uniforms;
      uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize()) *
                     Matrix::MakeTranslation({100.0, 100.0, 0.0});
      BoxVertexShader::BindUniformBuffer(
          cmd, pass.GetTransientsBuffer().EmplaceUniform(uniforms));

      if (!pass.RecordCommand(cmd)) {
        return false;
      }
    }

    return true;
  };
  // OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace impeller
