// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/base/strings.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/fixtures/array.frag.h"
#include "impeller/fixtures/array.vert.h"
#include "impeller/fixtures/box_fade.frag.h"
#include "impeller/fixtures/box_fade.vert.h"
#include "impeller/fixtures/colors.frag.h"
#include "impeller/fixtures/colors.vert.h"
#include "impeller/fixtures/impeller.frag.h"
#include "impeller/fixtures/impeller.vert.h"
#include "impeller/fixtures/inactive_uniforms.frag.h"
#include "impeller/fixtures/inactive_uniforms.vert.h"
#include "impeller/fixtures/instanced_draw.frag.h"
#include "impeller/fixtures/instanced_draw.vert.h"
#include "impeller/fixtures/mipmaps.frag.h"
#include "impeller/fixtures/mipmaps.vert.h"
#include "impeller/fixtures/test_texture.frag.h"
#include "impeller/fixtures/test_texture.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/surface.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

using RendererTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(RendererTest);

TEST_P(RendererTest, CanCreateBoxPrimitive) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);

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
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);
  SinglePassCallback callback = [&](RenderPass& pass) {
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    static bool wireframe;
    ImGui::Checkbox("Wireframe", &wireframe);
    ImGui::End();

    desc->SetPolygonMode(wireframe ? PolygonMode::kLine : PolygonMode::kFill);
    auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();

    assert(pipeline && pipeline->IsValid());

    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   Matrix::MakeScale(GetContentScale());
    VS::BindUniformBuffer(cmd,
                          pass.GetTransientsBuffer().EmplaceUniform(uniforms));

    FS::FrameInfo frame_info;
    frame_info.current_time = GetSecondsElapsed();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    FS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    FS::BindContents1(cmd, boston, sampler);
    FS::BindContents2(cmd, bridge, sampler);
    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanRenderPerspectiveCube) {
  using VS = ColorsVertexShader;
  using FS = ColorsFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetCullMode(CullMode::kBackFace);
  desc->SetWindingOrder(WindingOrder::kCounterClockwise);
  desc->SetSampleCount(SampleCount::kCount4);
  auto pipeline =
      context->GetPipelineLibrary()->GetPipeline(std::move(desc)).Get();
  ASSERT_TRUE(pipeline);

  struct Cube {
    VS::PerVertexData vertices[8] = {
        // -Z
        {{-1, -1, -1}, Color::Red()},
        {{1, -1, -1}, Color::Yellow()},
        {{1, 1, -1}, Color::Green()},
        {{-1, 1, -1}, Color::Blue()},
        // +Z
        {{-1, -1, 1}, Color::Green()},
        {{1, -1, 1}, Color::Blue()},
        {{1, 1, 1}, Color::Red()},
        {{-1, 1, 1}, Color::Yellow()},
    };
    uint16_t indices[36] = {
        1, 5, 2, 2, 5, 6,  // +X
        4, 0, 7, 7, 0, 3,  // -X
        4, 5, 0, 0, 5, 1,  // +Y
        3, 2, 7, 7, 2, 6,  // -Y
        5, 4, 6, 6, 4, 7,  // +Z
        0, 1, 3, 3, 1, 2,  // -Z
    };
  } cube;

  VertexBuffer vertex_buffer;
  {
    auto device_buffer = context->GetResourceAllocator()->CreateBufferWithCopy(
        reinterpret_cast<uint8_t*>(&cube), sizeof(cube));
    vertex_buffer.vertex_buffer = {
        .buffer = device_buffer,
        .range = Range(offsetof(Cube, vertices), sizeof(Cube::vertices))};
    vertex_buffer.index_buffer = {
        .buffer = device_buffer,
        .range = Range(offsetof(Cube, indices), sizeof(Cube::indices))};
    vertex_buffer.vertex_count = 36;
    vertex_buffer.index_type = IndexType::k16bit;
  }

  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  Vector3 euler_angles;
  SinglePassCallback callback = [&](RenderPass& pass) {
    static Degrees fov_y(60);
    static Scalar distance = 10;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Field of view", &fov_y.degrees, 0, 180);
    ImGui::SliderFloat("Camera distance", &distance, 0, 30);
    ImGui::End();

    Command cmd;
    cmd.label = "Perspective Cube";
    cmd.pipeline = pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    Scalar time = GetSecondsElapsed();
    euler_angles = Vector3(0.19 * time, 0.7 * time, 0.43 * time);

    uniforms.mvp =
        Matrix::MakePerspective(fov_y, pass.GetRenderTargetSize(), 0, 10) *
        Matrix::MakeTranslation({0, 0, distance}) *
        Matrix::MakeRotationX(Radians(euler_angles.x)) *
        Matrix::MakeRotationY(Radians(euler_angles.y)) *
        Matrix::MakeRotationZ(Radians(euler_angles.z));
    VS::BindUniformBuffer(cmd,
                          pass.GetTransientsBuffer().EmplaceUniform(uniforms));
    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanRenderMultiplePrimitives) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto desc = BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);
  auto box_pipeline =
      context->GetPipelineLibrary()->GetPipeline(std::move(desc)).Get();
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
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  SinglePassCallback callback = [&](RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    FS::FrameInfo frame_info;
    frame_info.current_time = GetSecondsElapsed();
    frame_info.cursor_position = GetCursorPosition();
    frame_info.window_size.x = GetWindowSize().width;
    frame_info.window_size.y = GetWindowSize().height;

    FS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    FS::BindContents1(cmd, boston, sampler);
    FS::BindContents2(cmd, bridge, sampler);

    for (size_t i = 0; i < 1; i++) {
      for (size_t j = 0; j < 1; j++) {
        VS::UniformBuffer uniforms;
        uniforms.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                       Matrix::MakeScale(GetContentScale()) *
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
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanRenderToTexture) {
  using VS = BoxFadeVertexShader;
  using FS = BoxFadeFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using BoxPipelineBuilder = PipelineBuilder<VS, FS>;
  auto pipeline_desc =
      BoxPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto box_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
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
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);
  std::shared_ptr<RenderPass> r2t_pass;
  auto cmd_buffer = context->CreateCommandBuffer();
  ASSERT_TRUE(cmd_buffer);
  {
    ColorAttachment color0;
    color0.load_action = LoadAction::kClear;
    color0.store_action = StoreAction::kStore;

    TextureDescriptor texture_descriptor;
    ASSERT_NE(pipeline_desc->GetColorAttachmentDescriptor(0u), nullptr);
    texture_descriptor.format =
        pipeline_desc->GetColorAttachmentDescriptor(0u)->format;
    texture_descriptor.storage_mode = StorageMode::kHostVisible;
    texture_descriptor.size = {400, 400};
    texture_descriptor.mip_count = 1u;
    texture_descriptor.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);

    color0.texture =
        context->GetResourceAllocator()->CreateTexture(texture_descriptor);

    ASSERT_TRUE(color0.IsValid());

    color0.texture->SetLabel("r2t_target");

    StencilAttachment stencil0;
    stencil0.load_action = LoadAction::kClear;
    stencil0.store_action = StoreAction::kDontCare;
    TextureDescriptor stencil_texture_desc;
    stencil_texture_desc.storage_mode = StorageMode::kDeviceTransient;
    stencil_texture_desc.size = texture_descriptor.size;
    stencil_texture_desc.format = PixelFormat::kS8UInt;
    stencil_texture_desc.usage =
        static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
    stencil0.texture =
        context->GetResourceAllocator()->CreateTexture(stencil_texture_desc);

    RenderTarget r2t_desc;
    r2t_desc.SetColorAttachment(color0, 0u);
    r2t_desc.SetStencilAttachment(stencil0);
    r2t_pass = cmd_buffer->CreateRenderPass(r2t_desc);
    ASSERT_TRUE(r2t_pass && r2t_pass->IsValid());
  }

  Command cmd;
  cmd.label = "Box";
  cmd.pipeline = box_pipeline;

  cmd.BindVertices(vertex_buffer);

  FS::FrameInfo frame_info;
  frame_info.current_time = GetSecondsElapsed();
  frame_info.cursor_position = GetCursorPosition();
  frame_info.window_size.x = GetWindowSize().width;
  frame_info.window_size.y = GetWindowSize().height;

  FS::BindFrameInfo(cmd,
                    r2t_pass->GetTransientsBuffer().EmplaceUniform(frame_info));
  FS::BindContents1(cmd, boston, sampler);
  FS::BindContents2(cmd, bridge, sampler);

  VS::UniformBuffer uniforms;
  uniforms.mvp = Matrix::MakeOrthographic(ISize{1024, 768}) *
                 Matrix::MakeTranslation({50.0f, 50.0f, 0.0f});
  VS::BindUniformBuffer(
      cmd, r2t_pass->GetTransientsBuffer().EmplaceUniform(uniforms));
  ASSERT_TRUE(r2t_pass->AddCommand(std::move(cmd)));
  ASSERT_TRUE(r2t_pass->EncodeCommands());
}

TEST_P(RendererTest, CanRenderInstanced) {
  if (GetParam() == PlaygroundBackend::kOpenGLES) {
    GTEST_SKIP_("Instancing is not supported on OpenGL.");
  }
  using VS = InstancedDrawVertexShader;
  using FS = InstancedDrawFragmentShader;

  VertexBufferBuilder<VS::PerVertexData> builder;

  ASSERT_EQ(Tessellator::Result::kSuccess,
            Tessellator{}.Tessellate(
                FillType::kPositive,
                PathBuilder{}
                    .AddRect(Rect::MakeXYWH(10, 10, 100, 100))
                    .TakePath()
                    .CreatePolyline(1.0f),
                [&builder](const float* vertices, size_t vertices_size,
                           const uint16_t* indices, size_t indices_size) {
                  for (auto i = 0u; i < vertices_size; i += 2) {
                    VS::PerVertexData data;
                    data.vtx = {vertices[i], vertices[i + 1]};
                    builder.AppendVertex(data);
                  }
                  for (auto i = 0u; i < indices_size; i++) {
                    builder.AppendIndex(indices[i]);
                  }
                  return true;
                }));

  ASSERT_NE(GetContext(), nullptr);
  auto pipeline =
      GetContext()
          ->GetPipelineLibrary()
          ->GetPipeline(PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(
                            *GetContext())
                            ->SetSampleCount(SampleCount::kCount4))
          .Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  Command cmd;
  cmd.pipeline = pipeline;
  cmd.label = "InstancedDraw";

  static constexpr size_t kInstancesCount = 5u;
  VS::InstanceInfo<kInstancesCount> instances;
  for (size_t i = 0; i < kInstancesCount; i++) {
    instances.colors[i] = Color::Random();
  }

  ASSERT_TRUE(OpenPlaygroundHere([&](RenderPass& pass) -> bool {
    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     Matrix::MakeScale(GetContentScale());
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));
    VS::BindInstanceInfo(
        cmd, pass.GetTransientsBuffer().EmplaceStorageBuffer(instances));
    cmd.BindVertices(builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

    cmd.instance_count = kInstancesCount;
    pass.AddCommand(cmd);
    return true;
  }));
}

TEST_P(RendererTest, CanBlitTextureToTexture) {
  auto context = GetContext();
  ASSERT_TRUE(context);

  using VS = MipmapsVertexShader;
  using FS = MipmapsFragmentShader;
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);
  auto mipmaps_pipeline =
      context->GetPipelineLibrary()->GetPipeline(std::move(desc)).Get();
  ASSERT_TRUE(mipmaps_pipeline);

  TextureDescriptor texture_desc;
  texture_desc.storage_mode = StorageMode::kHostVisible;
  texture_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_desc.size = {800, 600};
  texture_desc.mip_count = 1u;
  texture_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget) |
      static_cast<TextureUsageMask>(TextureUsage::kShaderRead);
  auto texture = context->GetResourceAllocator()->CreateTexture(texture_desc);
  ASSERT_TRUE(texture);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  auto size = Point(boston->GetSize());
  vertex_builder.AddVertices({
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, 0}, {1.0, 0.0}},       // 2
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, size.y}, {0.0, 1.0}},       // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    auto buffer = context->CreateCommandBuffer();
    if (!buffer) {
      return false;
    }
    buffer->SetLabel("Playground Command Buffer");

    {
      auto pass = buffer->CreateBlitPass();
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Blit Pass");

      if (render_target.GetColorAttachments().empty()) {
        return false;
      }

      // Blit `bridge` to the top left corner of the texture.
      pass->AddCopy(bridge, texture);

      if (!pass->EncodeCommands(context->GetResourceAllocator())) {
        return false;
      }
    }

    {
      auto pass = buffer->CreateRenderPass(render_target);
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Render Pass");
      {
        Command cmd;
        cmd.label = "Image";
        cmd.pipeline = mipmaps_pipeline;

        cmd.BindVertices(vertex_buffer);

        VS::FrameInfo frame_info;
        frame_info.mvp = Matrix::MakeOrthographic(pass->GetRenderTargetSize()) *
                         Matrix::MakeScale(GetContentScale());
        VS::BindFrameInfo(
            cmd, pass->GetTransientsBuffer().EmplaceUniform(frame_info));

        FS::FragInfo frag_info;
        frag_info.lod = 0;
        FS::BindFragInfo(cmd,
                         pass->GetTransientsBuffer().EmplaceUniform(frag_info));

        auto sampler = context->GetSamplerLibrary()->GetSampler({});
        FS::BindTex(cmd, texture, sampler);

        pass->AddCommand(std::move(cmd));
      }
      pass->EncodeCommands();
    }

    if (!buffer->SubmitCommands()) {
      return false;
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanBlitTextureToBuffer) {
  auto context = GetContext();
  ASSERT_TRUE(context);

  using VS = MipmapsVertexShader;
  using FS = MipmapsFragmentShader;
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);
  auto mipmaps_pipeline =
      context->GetPipelineLibrary()->GetPipeline(std::move(desc)).Get();
  ASSERT_TRUE(mipmaps_pipeline);

  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(bridge && boston);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  TextureDescriptor texture_desc;
  texture_desc.storage_mode = StorageMode::kHostVisible;
  texture_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_desc.size = bridge->GetTextureDescriptor().size;
  texture_desc.mip_count = 1u;
  texture_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget) |
      static_cast<TextureUsageMask>(TextureUsage::kShaderWrite) |
      static_cast<TextureUsageMask>(TextureUsage::kShaderRead);
  DeviceBufferDescriptor device_buffer_desc;
  device_buffer_desc.storage_mode = StorageMode::kHostVisible;
  device_buffer_desc.size =
      bridge->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  auto device_buffer =
      context->GetResourceAllocator()->CreateBuffer(device_buffer_desc);

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  auto size = Point(boston->GetSize());
  vertex_builder.AddVertices({
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, 0}, {1.0, 0.0}},       // 2
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, size.y}, {0.0, 1.0}},       // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    {
      auto buffer = context->CreateCommandBuffer();
      if (!buffer) {
        return false;
      }
      buffer->SetLabel("Playground Command Buffer");
      auto pass = buffer->CreateBlitPass();
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Blit Pass");

      if (render_target.GetColorAttachments().empty()) {
        return false;
      }

      // Blit `bridge` to the top left corner of the texture.
      pass->AddCopy(bridge, device_buffer);

      pass->EncodeCommands(context->GetResourceAllocator());

      if (!buffer->SubmitCommands()) {
        return false;
      }
    }

    {
      auto buffer = context->CreateCommandBuffer();
      if (!buffer) {
        return false;
      }
      buffer->SetLabel("Playground Command Buffer");

      auto pass = buffer->CreateRenderPass(render_target);
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Render Pass");
      {
        Command cmd;
        cmd.label = "Image";
        cmd.pipeline = mipmaps_pipeline;

        cmd.BindVertices(vertex_buffer);

        VS::FrameInfo frame_info;
        frame_info.mvp = Matrix::MakeOrthographic(pass->GetRenderTargetSize()) *
                         Matrix::MakeScale(GetContentScale());
        VS::BindFrameInfo(
            cmd, pass->GetTransientsBuffer().EmplaceUniform(frame_info));

        FS::FragInfo frag_info;
        frag_info.lod = 0;
        FS::BindFragInfo(cmd,
                         pass->GetTransientsBuffer().EmplaceUniform(frag_info));

        auto sampler = context->GetSamplerLibrary()->GetSampler({});
        auto buffer_view = device_buffer->AsBufferView();
        auto texture =
            context->GetResourceAllocator()->CreateTexture(texture_desc);
        if (!texture->SetContents(buffer_view.contents,
                                  buffer_view.range.length)) {
          VALIDATION_LOG << "Could not upload texture to device memory";
          return false;
        }
        FS::BindTex(cmd, texture, sampler);

        pass->AddCommand(std::move(cmd));
      }
      pass->EncodeCommands();
      if (!buffer->SubmitCommands()) {
        return false;
      }
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanGenerateMipmaps) {
  auto context = GetContext();
  ASSERT_TRUE(context);

  using VS = MipmapsVertexShader;
  using FS = MipmapsFragmentShader;
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);
  auto mipmaps_pipeline =
      context->GetPipelineLibrary()->GetPipeline(std::move(desc)).Get();
  ASSERT_TRUE(mipmaps_pipeline);

  auto boston = CreateTextureForFixture("boston.jpg", true);
  ASSERT_TRUE(boston);

  // Vertex buffer.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  auto size = Point(boston->GetSize());
  vertex_builder.AddVertices({
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, 0}, {1.0, 0.0}},       // 2
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, 0}, {0.0, 0.0}},            // 1
      {{size.x, size.y}, {1.0, 1.0}},  // 3
      {{0, size.y}, {0.0, 1.0}},       // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetResourceAllocator());
  ASSERT_TRUE(vertex_buffer);

  bool first_frame = true;
  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    const char* mip_filter_names[] = {"Nearest", "Linear"};
    const MipFilter mip_filters[] = {MipFilter::kNearest, MipFilter::kLinear};
    const char* min_filter_names[] = {"Nearest", "Linear"};
    const MinMagFilter min_filters[] = {MinMagFilter::kNearest,
                                        MinMagFilter::kLinear};

    // UI state.
    static int selected_mip_filter = 1;
    static int selected_min_filter = 0;
    static float lod = 4.5;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Mip filter", &selected_mip_filter, mip_filter_names,
                 sizeof(mip_filter_names) / sizeof(char*));
    ImGui::Combo("Min filter", &selected_min_filter, min_filter_names,
                 sizeof(min_filter_names) / sizeof(char*));
    ImGui::SliderFloat("LOD", &lod, 0, boston->GetMipCount() - 1);
    ImGui::End();

    auto buffer = context->CreateCommandBuffer();
    if (!buffer) {
      return false;
    }
    buffer->SetLabel("Playground Command Buffer");

    if (first_frame) {
      auto pass = buffer->CreateBlitPass();
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Blit Pass");

      pass->GenerateMipmap(boston, "Boston Mipmap");

      pass->EncodeCommands(context->GetResourceAllocator());
    }

    first_frame = false;

    {
      auto pass = buffer->CreateRenderPass(render_target);
      if (!pass) {
        return false;
      }
      pass->SetLabel("Playground Render Pass");
      {
        Command cmd;
        cmd.label = "Image LOD";
        cmd.pipeline = mipmaps_pipeline;

        cmd.BindVertices(vertex_buffer);

        VS::FrameInfo frame_info;
        frame_info.mvp = Matrix::MakeOrthographic(pass->GetRenderTargetSize()) *
                         Matrix::MakeScale(GetContentScale());
        VS::BindFrameInfo(
            cmd, pass->GetTransientsBuffer().EmplaceUniform(frame_info));

        FS::FragInfo frag_info;
        frag_info.lod = lod;
        FS::BindFragInfo(cmd,
                         pass->GetTransientsBuffer().EmplaceUniform(frag_info));

        SamplerDescriptor sampler_desc;
        sampler_desc.mip_filter = mip_filters[selected_mip_filter];
        sampler_desc.min_filter = min_filters[selected_min_filter];
        auto sampler = context->GetSamplerLibrary()->GetSampler(sampler_desc);
        FS::BindTex(cmd, boston, sampler);

        pass->AddCommand(std::move(cmd));
      }
      pass->EncodeCommands();
    }

    if (!buffer->SubmitCommands()) {
      return false;
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, TheImpeller) {
  using VS = ImpellerVertexShader;
  using FS = ImpellerFragmentShader;

  auto context = GetContext();
  auto pipeline_descriptor =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_descriptor.has_value());
  pipeline_descriptor->SetSampleCount(SampleCount::kCount4);
  auto pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_descriptor).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  auto blue_noise = CreateTextureForFixture("blue_noise.png");
  SamplerDescriptor noise_sampler_desc;
  noise_sampler_desc.width_address_mode = SamplerAddressMode::kRepeat;
  noise_sampler_desc.height_address_mode = SamplerAddressMode::kRepeat;
  auto noise_sampler =
      context->GetSamplerLibrary()->GetSampler(noise_sampler_desc);

  auto cube_map = CreateTextureCubeForFixture(
      {"table_mountain_px.png", "table_mountain_nx.png",
       "table_mountain_py.png", "table_mountain_ny.png",
       "table_mountain_pz.png", "table_mountain_nz.png"});
  auto cube_map_sampler = context->GetSamplerLibrary()->GetSampler({});

  SinglePassCallback callback = [&](RenderPass& pass) {
    auto size = pass.GetRenderTargetSize();

    Command cmd;
    cmd.pipeline = pipeline;
    cmd.label = "Impeller SDF scene";
    VertexBufferBuilder<VS::PerVertexData> builder;
    builder.AddVertices({{Point()},
                         {Point(0, size.height)},
                         {Point(size.width, 0)},
                         {Point(size.width, 0)},
                         {Point(0, size.height)},
                         {Point(size.width, size.height)}});
    cmd.BindVertices(builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(size);
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    FS::FragInfo fs_uniform;
    fs_uniform.texture_size = Point(size);
    fs_uniform.time = GetSecondsElapsed();
    FS::BindFragInfo(cmd,
                     pass.GetTransientsBuffer().EmplaceUniform(fs_uniform));
    FS::BindBlueNoise(cmd, blue_noise, noise_sampler);
    FS::BindCubeMap(cmd, cube_map, cube_map_sampler);

    pass.AddCommand(cmd);
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, ArrayUniforms) {
  using VS = ArrayVertexShader;
  using FS = ArrayFragmentShader;

  auto context = GetContext();
  auto pipeline_descriptor =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_descriptor.has_value());
  pipeline_descriptor->SetSampleCount(SampleCount::kCount4);
  auto pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_descriptor).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  SinglePassCallback callback = [&](RenderPass& pass) {
    auto size = pass.GetRenderTargetSize();

    Command cmd;
    cmd.pipeline = pipeline;
    cmd.label = "Google Dots";
    VertexBufferBuilder<VS::PerVertexData> builder;
    builder.AddVertices({{Point()},
                         {Point(0, size.height)},
                         {Point(size.width, 0)},
                         {Point(size.width, 0)},
                         {Point(0, size.height)},
                         {Point(size.width, size.height)}});
    cmd.BindVertices(builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

    VS::FrameInfo frame_info;
    frame_info.mvp =
        Matrix::MakeOrthographic(size) * Matrix::MakeScale(GetContentScale());
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    auto time = GetSecondsElapsed();
    auto y_pos = [&time](float x) {
      return 400 + 10 * std::cos(time * 5 + x / 6);
    };

    FS::FragInfo fs_uniform = {
        .circle_positions = {Point(430, y_pos(0)), Point(480, y_pos(1)),
                             Point(530, y_pos(2)), Point(580, y_pos(3))},
        .colors = {Color::MakeRGBA8(66, 133, 244, 255),
                   Color::MakeRGBA8(219, 68, 55, 255),
                   Color::MakeRGBA8(244, 180, 0, 255),
                   Color::MakeRGBA8(15, 157, 88, 255)},
    };
    FS::BindFragInfo(cmd,
                     pass.GetTransientsBuffer().EmplaceUniform(fs_uniform));

    pass.AddCommand(cmd);
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, InactiveUniforms) {
  using VS = InactiveUniformsVertexShader;
  using FS = InactiveUniformsFragmentShader;

  auto context = GetContext();
  auto pipeline_descriptor =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_descriptor.has_value());
  pipeline_descriptor->SetSampleCount(SampleCount::kCount4);
  auto pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_descriptor).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  SinglePassCallback callback = [&](RenderPass& pass) {
    auto size = pass.GetRenderTargetSize();

    Command cmd;
    cmd.pipeline = pipeline;
    cmd.label = "Inactive Uniform";
    VertexBufferBuilder<VS::PerVertexData> builder;
    builder.AddVertices({{Point()},
                         {Point(0, size.height)},
                         {Point(size.width, 0)},
                         {Point(size.width, 0)},
                         {Point(0, size.height)},
                         {Point(size.width, size.height)}});
    cmd.BindVertices(builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

    VS::FrameInfo frame_info;
    frame_info.mvp =
        Matrix::MakeOrthographic(size) * Matrix::MakeScale(GetContentScale());
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    FS::FragInfo fs_uniform = {.unused_color = Color::Red(),
                               .color = Color::Green()};
    FS::BindFragInfo(cmd,
                     pass.GetTransientsBuffer().EmplaceUniform(fs_uniform));

    pass.AddCommand(cmd);
    return true;
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanCreateCPUBackedTexture) {
  if (GetParam() == PlaygroundBackend::kOpenGLES) {
    GTEST_SKIP_("CPU backed textures are not supported on OpenGLES.");
  }

  auto context = GetContext();
  auto allocator = context->GetResourceAllocator();
  size_t dimension = 2;

  do {
    ISize size(dimension, dimension);
    TextureDescriptor texture_descriptor;
    texture_descriptor.storage_mode = StorageMode::kHostVisible;
    texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
    texture_descriptor.size = size;
    auto row_bytes =
        std::max(static_cast<uint16_t>(size.width * 4),
                 allocator->MinimumBytesPerRow(texture_descriptor.format));
    auto buffer_size = size.height * row_bytes;

    DeviceBufferDescriptor buffer_descriptor;
    buffer_descriptor.storage_mode = StorageMode::kHostVisible;
    buffer_descriptor.size = buffer_size;

    auto buffer = allocator->CreateBuffer(buffer_descriptor);

    ASSERT_TRUE(buffer);

    auto texture = buffer->AsTexture(*allocator, texture_descriptor, row_bytes);

    ASSERT_TRUE(texture);
    ASSERT_TRUE(texture->IsValid());

    dimension *= 2;
  } while (dimension <= 8192);
}

TEST_P(RendererTest, DefaultIndexSize) {
  using VS = BoxFadeVertexShader;

  // Default to 16bit index buffer size, as this is a reasonable default and
  // supported on all backends without extensions.
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  ASSERT_EQ(vertex_builder.GetIndexType(), IndexType::k16bit);
}

TEST_P(RendererTest, VertexBufferBuilder) {
  // Does not create index buffer if one is provided.
  using VS = BoxFadeVertexShader;
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.SetLabel("Box");
  vertex_builder.AddVertices({
      {{100, 100, 0.0}, {0.0, 0.0}},  // 1
      {{800, 100, 0.0}, {1.0, 0.0}},  // 2
      {{800, 800, 0.0}, {1.0, 1.0}},  // 3
      {{100, 800, 0.0}, {0.0, 1.0}},  // 4
  });
  vertex_builder.AppendIndex(0);
  vertex_builder.AppendIndex(1);
  vertex_builder.AppendIndex(2);
  vertex_builder.AppendIndex(1);
  vertex_builder.AppendIndex(2);
  vertex_builder.AppendIndex(3);

  ASSERT_EQ(vertex_builder.GetIndexCount(), 6u);
  ASSERT_EQ(vertex_builder.GetVertexCount(), 4u);
}

}  // namespace testing
}  // namespace impeller
