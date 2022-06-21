// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "impeller/fixtures/box_fade.frag.h"
#include "impeller/fixtures/box_fade.vert.h"
#include "impeller/fixtures/colors.frag.h"
#include "impeller/fixtures/colors.vert.h"
#include "impeller/fixtures/impeller.frag.h"
#include "impeller/fixtures/impeller.vert.h"
#include "impeller/fixtures/instanced_draw.frag.h"
#include "impeller/fixtures/instanced_draw.vert.h"
#include "impeller/fixtures/test_texture.frag.h"
#include "impeller/fixtures/test_texture.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/playground.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/sampler.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/surface.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

using RendererTest = Playground;
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
  SinglePassCallback callback = [&](RenderPass& pass) {
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   Matrix::MakeScale(GetContentScale());
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
  OpenPlaygroundHere(callback);
}

TEST_P(RendererTest, CanRenderPerspectiveCube) {
  using VS = ColorsVertexShader;
  using FS = ColorsFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount4);
  auto pipeline =
      context->GetPipelineLibrary()->GetRenderPipeline(std::move(desc)).get();
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
    auto device_buffer =
        context->GetPermanentsAllocator()->CreateBufferWithCopy(
            reinterpret_cast<uint8_t*>(&cube), sizeof(cube));
    vertex_buffer.vertex_buffer = {
        .buffer = device_buffer,
        .range = Range(offsetof(Cube, vertices), sizeof(Cube::vertices))};
    vertex_buffer.index_buffer = {
        .buffer = device_buffer,
        .range = Range(offsetof(Cube, indices), sizeof(Cube::indices))};
    vertex_buffer.index_count = 36;
    vertex_buffer.index_type = IndexType::k16bit;
  }

  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  Vector3 euler_angles;
  bool first_frame = true;
  SinglePassCallback callback = [&](RenderPass& pass) {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({400, 80});
      ImGui::SetNextWindowPos({20, 20});
    }

    static Degrees fov_y(60);
    static Scalar distance = 10;

    ImGui::Begin("Controls");
    ImGui::SliderFloat("Field of view", &fov_y.degrees, 0, 180);
    ImGui::SliderFloat("Camera distance", &distance, 0, 30);
    ImGui::End();

    Command cmd;
    cmd.label = "Perspective Cube";
    cmd.pipeline = pipeline;

    cmd.BindVertices(vertex_buffer);

    VS::UniformBuffer uniforms;
    Scalar time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    euler_angles = Vector3(0.19 * time, 0.7 * time, 0.43 * time);

    uniforms.mvp =
        Matrix::MakePerspective(fov_y, pass.GetRenderTargetSize(), 0, 10) *
        Matrix::MakeTranslation({0, 0, -distance}) *
        Matrix::MakeRotationX(Radians(euler_angles.x)) *
        Matrix::MakeRotationY(Radians(euler_angles.y)) *
        Matrix::MakeRotationZ(Radians(euler_angles.z));
    VS::BindUniformBuffer(cmd,
                          pass.GetTransientsBuffer().EmplaceUniform(uniforms));

    cmd.primitive_type = PrimitiveType::kTriangle;
    cmd.cull_mode = CullMode::kBackFace;
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

  SinglePassCallback callback = [&](RenderPass& pass) {
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
      context->GetPipelineLibrary()->GetRenderPipeline(pipeline_desc).get();
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
  ASSERT_TRUE(r2t_pass->EncodeCommands(context->GetTransientsAllocator()));
}

#if IMPELLER_ENABLE_METAL
TEST_P(RendererTest, CanRenderInstanced) {
  if (GetBackend() != PlaygroundBackend::kMetal) {
    GTEST_SKIP_("Instancing is only supported on Metal.");
  }
  using VS = InstancedDrawVertexShader;
  using FS = InstancedDrawFragmentShader;

  VertexBufferBuilder<VS::PerVertexData> builder;

  ASSERT_EQ(
      Tessellator::Result::kSuccess,
      Tessellator{}.Tessellate(FillType::kPositive,
                               PathBuilder{}
                                   .AddRect(Rect::MakeXYWH(10, 10, 100, 100))
                                   .TakePath()
                                   .CreatePolyline(),
                               [&builder](Point vtx) {
                                 VS::PerVertexData data;
                                 data.vtx = vtx;
                                 builder.AppendVertex(data);
                               }));

  ASSERT_NE(GetContext(), nullptr);
  auto pipeline =
      GetContext()
          ->GetPipelineLibrary()
          ->GetRenderPipeline(
              PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(
                  *GetContext())
                  ->SetSampleCount(SampleCount::kCount4))
          .get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  Command cmd;
  cmd.pipeline = pipeline;
  cmd.label = "InstancedDraw";

  static constexpr size_t kInstancesCount = 5u;
  std::vector<VS::InstanceInfo> instances;
  for (size_t i = 0; i < kInstancesCount; i++) {
    VS::InstanceInfo info;
    info.colors = Color::Random();
    instances.emplace_back(info);
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
#endif  // IMPELLER_ENABLE_METAL

TEST_P(RendererTest, TheImpeller) {
  using VS = ImpellerVertexShader;
  using FS = ImpellerFragmentShader;

  auto context = GetContext();
  auto pipeline_descriptor =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_descriptor.has_value());
  pipeline_descriptor->SetSampleCount(SampleCount::kCount4);
  auto pipeline = context->GetPipelineLibrary()
                      ->GetRenderPipeline(pipeline_descriptor)
                      .get();
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
    cmd.cull_mode = CullMode::kNone;

    VS::FrameInfo vs_uniform;
    vs_uniform.mvp = Matrix::MakeOrthographic(size);
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(vs_uniform));

    FS::FragInfo fs_uniform;
    fs_uniform.texture_size = Point(size);
    fs_uniform.time = fml::TimePoint::Now().ToEpochDelta().ToSecondsF();
    FS::BindFragInfo(cmd,
                     pass.GetTransientsBuffer().EmplaceUniform(fs_uniform));
    FS::BindBlueNoise(cmd, blue_noise, noise_sampler);
    FS::BindCubeMap(cmd, cube_map, cube_map_sampler);

    pass.AddCommand(cmd);
    return true;
  };
  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace impeller
