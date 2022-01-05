// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"
#include "flutter/impeller/fixtures/box_fade.frag.h"
#include "flutter/impeller/fixtures/box_fade.vert.h"
#include "flutter/impeller/fixtures/test_texture.frag.h"
#include "flutter/impeller/fixtures/test_texture.vert.h"
#include "flutter/testing/testing.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/playground.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/surface.h"
#include "impeller/renderer/tessellator.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {
namespace testing {

using RendererTest = Playground;

TEST_F(RendererTest, CanCreateBoxPrimitive) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  auto box_pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  ASSERT_TRUE(box_pipeline);

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
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
  Renderer::RenderCallback callback = [&](RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
    VS::BindUniformBuffer(cmd,
                          pass.GetTransientsBuffer().EmplaceUniform(uniforms));

    FS::FrameInfo frame_info;
    frame_info.current_time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    FS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    FS::BindContents1(cmd, boston, sampler);
    FS::BindContents2(cmd, bridge, sampler);

    cmd.primitive_type = PrimitiveType::kTriangle;
    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  // OpenPlaygroundHere(callback);
}

TEST_F(RendererTest, CanRenderMultiplePrimitives) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  auto box_pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
  ASSERT_TRUE(box_pipeline);

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
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

  Renderer::RenderCallback callback = [&](RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    FS::FrameInfo frame_info;
    frame_info.current_time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    FS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    FS::BindContents1(cmd, boston, sampler);
    FS::BindContents2(cmd, bridge, sampler);

    cmd.primitive_type = PrimitiveType::kTriangle;

    for (size_t i = 0; i < 1; i++) {
      for (size_t j = 0; j < 1; j++) {
        VS::UniformBuffer uniforms;
        uniforms.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                       Matrix::MakeTranslation({i * 50.0f, j * 50.0f, 0.0f});
        VS::BindUniformBuffer(
            cmd, pass.GetTransientsBuffer().EmplaceUniform(uniforms));
        if (!pass.AddCommand(cmd)) {
          return false;
        }
      }
    }

    return true;
  };
  // OpenPlaygroundHere(callback);
}

TEST_F(RendererTest, CanRenderToTexture) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto pipeline_desc =
      BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto box_pipeline = context->GetPipelineLibrary()
                          ->GetRenderPipeline(std::move(pipeline_desc))
                          .get();
  ASSERT_TRUE(box_pipeline);

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
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

  std::shared_ptr<RenderPass> r2t_pass;

  {
    ColorAttachment color0;
    color0.load_action = LoadAction::kClear;
    color0.store_action = StoreAction::kStore;

    TextureDescriptor texture_descriptor;
    ASSERT_NE(pipeline_desc->GetColorAttachmentDescriptor(0u), nullptr);
    texture_descriptor.format =
        pipeline_desc->GetColorAttachmentDescriptor(0u)->format;
    texture_descriptor.size = {400, 400};
    texture_descriptor.mip_count = 1u;
    texture_descriptor.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

    color0.texture = context->GetPermanentsAllocator()->CreateTexture(
        StorageMode::kHostVisible, texture_descriptor);

    ASSERT_TRUE(color0);

    color0.texture->SetLabel("r2t_target");

    StencilAttachment stencil0;
    stencil0.load_action = LoadAction::kClear;
    stencil0.store_action = StoreAction::kDontCare;
    TextureDescriptor stencil_texture_desc;
    stencil_texture_desc.size = texture_descriptor.size;
    stencil_texture_desc.format = PixelFormat::kS8UInt;
    stencil_texture_desc.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
    stencil0.texture = context->GetPermanentsAllocator()->CreateTexture(
        StorageMode::kDeviceTransient, stencil_texture_desc);

    RenderTarget r2t_desc;
    r2t_desc.SetColorAttachment(color0, 0u);
    r2t_desc.SetStencilAttachment(stencil0);
    auto cmd_buffer = context->CreateRenderCommandBuffer();
    r2t_pass = cmd_buffer->CreateRenderPass(r2t_desc);
    ASSERT_TRUE(r2t_pass && r2t_pass->IsValid());
  }

  Command cmd;
  cmd.label = "Box";
  cmd.pipeline = box_pipeline;

  cmd.BindVertices(vertex_buffer);

  FS::FrameInfo frame_info;
  frame_info.current_time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
  frame_info.cursor_position = GetCursorPosition();
  frame_info.window_size.x = GetWindowSize().width;
  frame_info.window_size.y = GetWindowSize().height;

  FS::BindFrameInfo(cmd,
                    r2t_pass->GetTransientsBuffer().EmplaceUniform(frame_info));
  FS::BindContents1(cmd, boston, sampler);
  FS::BindContents2(cmd, bridge, sampler);

  cmd.primitive_type = PrimitiveType::kTriangle;

  VS::UniformBuffer uniforms;
  uniforms.mvp = Matrix::MakeOrthographic(ISize{1024, 768}) *
                 Matrix::MakeTranslation({50.0f, 50.0f, 0.0f});
  VS::BindUniformBuffer(
      cmd, r2t_pass->GetTransientsBuffer().EmplaceUniform(uniforms));
  ASSERT_TRUE(r2t_pass->AddCommand(std::move(cmd)));
  ASSERT_TRUE(r2t_pass->EncodeCommands(*context->GetTransientsAllocator()));
}

}  // namespace testing
}  // namespace impeller
