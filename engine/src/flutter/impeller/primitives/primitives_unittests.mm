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
      {{100, 100, 0.0}, {Color::Red()}, {0.0, 0.0}},    // 1
      {{800, 100, 0.0}, {Color::Green()}, {1.0, 0.0}},  // 2
      {{800, 800, 0.0}, {Color::Blue()}, {1.0, 1.0}},   // 3

      {{100, 100, 0.0}, {Color::Cyan()}, {0.0, 0.0}},    // 1
      {{800, 800, 0.0}, {Color::White()}, {1.0, 1.0}},   // 3
      {{100, 800, 0.0}, {Color::Purple()}, {0.0, 1.0}},  // 4
  });
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(*context->GetPermanentsAllocator());
  ASSERT_TRUE(vertex_buffer);

  // Contents texture.
  Image image(flutter::testing::OpenFixtureAsMapping("image.png"));
  auto result = image.Decode();
  ASSERT_TRUE(result.IsValid());
  auto texture_descriptor = TextureDescriptor::MakeFromImageResult(result);
  ASSERT_TRUE(texture_descriptor.has_value());
  auto texture = context->GetPermanentsAllocator()->CreateTexture(
      StorageMode::kHostVisible, texture_descriptor.value());
  ASSERT_TRUE(texture);
  auto uploaded = texture->SetContents(result.GetAllocation()->GetMapping(),
                                       result.GetAllocation()->GetSize());
  ASSERT_TRUE(uploaded);
  auto sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);
  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) {
    BoxVertexShader::UniformBuffer uniforms;
    uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize().width,
                                            surface.GetSize().height);
    Command cmd;
    cmd.label = "Box";
    cmd.pipeline = box_pipeline;

    cmd.vertex_bindings.buffers[VertexDescriptor::kReservedVertexBufferIndex] =
        vertex_buffer.vertex_buffer;
    cmd.vertex_bindings
        .buffers[BoxVertexShader::kUniformUniformBuffer.binding] =
        pass.GetTransientsBuffer().EmplaceUniform(uniforms);

    cmd.fragment_bindings
        .textures[BoxFragmentShader::kInputContentsTexture.location] = texture;
    cmd.fragment_bindings
        .samplers[BoxFragmentShader::kInputContentsTexture.location] = sampler;

    cmd.index_buffer = vertex_buffer.index_buffer;
    cmd.index_count = vertex_buffer.index_count;
    cmd.primitive_type = PrimitiveType::kTriange;
    if (!pass.RecordCommand(std::move(cmd))) {
      return false;
    }
    return true;
  };
  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace impeller
