// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_renderer.h"

#include "flutter/fml/time/time_point.h"
#include "impeller/compositor/command.h"
#include "impeller/compositor/sampler_descriptor.h"
#include "impeller/compositor/surface.h"
#include "impeller/compositor/vertex_buffer_builder.h"
#include "impeller/primitives/box.frag.h"
#include "impeller/primitives/box.vert.h"

namespace impeller {

EntityRenderer::EntityRenderer(std::string shaders_directory)
    : Renderer(std::move(shaders_directory)),
      root_(std::make_shared<Entity>()) {
  root_->SetBackgroundColor(Color::DarkGray());

  auto context = GetContext();

  if (!context) {
    return;
  }

  box_primitive_ = std::make_shared<BoxPrimitive>(context);
  if (!box_primitive_) {
    return;
  }

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

  vertex_buffer_ =
      vertex_builder.CreateVertexBuffer(*context->GetPermanentsAllocator());

  if (!vertex_buffer_) {
    return;
  }

  is_valid_ = true;
}

EntityRenderer::~EntityRenderer() = default;

bool EntityRenderer::OnIsValid() const {
  return is_valid_;
}

bool EntityRenderer::OnRender(const Surface& surface, RenderPass& pass) {
  pass.SetLabel("EntityRenderer Render Pass");

  BoxVertexShader::UniformBuffer uniforms;

  uniforms.mvp = Matrix::MakeOrthographic(surface.GetSize());

  Command cmd;
  cmd.label = "Box";
  cmd.pipeline = box_primitive_->GetPipeline();
  cmd.vertex_bindings.buffers[box_primitive_->GetVertexBufferIndex()] =
      vertex_buffer_.vertex_buffer;
  cmd.vertex_bindings.buffers[BoxVertexShader::kUniformUniformBuffer.binding] =
      pass.GetTransientsBuffer().EmplaceUniform(uniforms);
  cmd.fragment_bindings.samplers[BoxFragmentShader::kInputContents1.binding] =
      GetContext()->GetSamplerLibrary()->GetSampler({});
  cmd.fragment_bindings.samplers[BoxFragmentShader::kInputContents2.binding] =
      GetContext()->GetSamplerLibrary()->GetSampler({});
  cmd.fragment_bindings.samplers[BoxFragmentShader::kInputContents3.binding] =
      GetContext()->GetSamplerLibrary()->GetSampler({});
  cmd.index_buffer = vertex_buffer_.index_buffer;
  cmd.index_count = vertex_buffer_.index_count;
  cmd.primitive_type = PrimitiveType::kTriange;
  if (!pass.RecordCommand(std::move(cmd))) {
    return false;
  }
  return true;
}

}  // namespace impeller
