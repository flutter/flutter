// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "impeller/compositor/command.h"
#include "impeller/compositor/command_buffer.h"
#include "impeller/compositor/pipeline_builder.h"
#include "impeller/compositor/pipeline_library.h"
#include "impeller/compositor/renderer.h"
#include "impeller/compositor/sampler_descriptor.h"
#include "impeller/compositor/surface.h"
#include "impeller/compositor/tessellator.h"
#include "impeller/compositor/vertex_buffer_builder.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/playground.h"
#include "impeller/primitives/box_fade.frag.h"
#include "impeller/primitives/box_fade.vert.h"

namespace impeller {
namespace testing {

using PrimitivesTest = Playground;

TEST_F(PrimitivesTest, CanCreateBoxPrimitive) {
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
  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize());
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
    if (!pass.RecordCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  // OpenPlaygroundHere(callback);
}

TEST_F(PrimitivesTest, CanRenderMultiplePrimitives) {
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

  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) {
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

    for (size_t i = 0; i < 50; i++) {
      for (size_t j = 0; j < 50; j++) {
        VS::UniformBuffer uniforms;
        uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize()) *
                       Matrix::MakeTranslation({i * 50.0f, j * 50.0f, 0.0f});
        VS::BindUniformBuffer(
            cmd, pass.GetTransientsBuffer().EmplaceUniform(uniforms));
        if (!pass.RecordCommand(cmd)) {
          return false;
        }
      }
    }

    return true;
  };
  // OpenPlaygroundHere(callback);
}

TEST_F(PrimitivesTest, CanRenderToTexture) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto pipeline_desc =
      BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
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
    RenderPassColorAttachment color0;
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

    RenderPassDescriptor r2t_desc;
    r2t_desc.SetColorAttachment(color0, 0u);
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
  ASSERT_TRUE(r2t_pass->RecordCommand(std::move(cmd)));
  ASSERT_TRUE(r2t_pass->Commit(*context->GetTransientsAllocator()));
}

TEST_F(PrimitivesTest, CanRenderPath) {
  auto path = PathBuilder{}.AddRect({10, 10, 100, 100}).CreatePath();
  ASSERT_FALSE(path.GetBoundingBox().IsZero());

  using BoxPipeline = PipelineT<BoxFadeVertexShader, BoxFadeFragmentShader>;
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;

  BoxPipeline box_pipeline(*GetContext());

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");

  Tessellator tessellator;
  ASSERT_TRUE(tessellator.Tessellate(
      path.SubdivideAdaptively({}), [&vertex_builder](Point point) {
        VS::PerVertexData vtx;
        vtx.vertex_position = {point.x, point.y, 0.0};
        vtx.texture_coordinates = {0.5, 0.5};
        vertex_builder.AppendVertex(vtx);
      }));

  auto context = GetContext();

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
    cmd.pipeline = box_pipeline.WaitAndGet();

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

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize());
    VS::BindUniformBuffer(cmd,
                          pass.GetTransientsBuffer().EmplaceUniform(uniforms));
    if (!pass.RecordCommand(cmd)) {
      return false;
    }

    return true;
  };
  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace impeller
