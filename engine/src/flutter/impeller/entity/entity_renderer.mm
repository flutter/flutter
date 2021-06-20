// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_renderer.h"
#include "impeller/compositor/command.h"
#include "impeller/compositor/vertex_buffer.h"
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

  is_valid_ = true;
}

EntityRenderer::~EntityRenderer() = default;

bool EntityRenderer::OnIsValid() const {
  return is_valid_;
}

bool EntityRenderer::OnRender(RenderPass& pass) {
  shader::BoxVertexInfo::UniformBuffer uniforms;
  uniforms.mvp = Matrix::MakeOrthographic({800, 600});
  VertexBufferBuilder vertices;
  vertices.AddVertices({
      {-0.5, 0.5},  //
      {0.5, 0.5},   //
      {0.5, -0.5},  //
      {-0.5, 0.5},  //
  });

  Command cmd;
  cmd.label = "Simple Box";
  cmd.pipeline = box_primitive_->GetPipeline();
  cmd.vertex_bindings
      .buffers[shader::BoxVertexInfo::kUniformUniformBuffer.location] =
      pass.GetTransientsBuffer().Emplace(uniforms);
  cmd.vertex_bindings
      .buffers[shader::BoxVertexInfo::kInputVertexPosition.location] =
      vertices.CreateVertexBuffer(pass.GetTransientsBuffer());
  cmd.index_buffer = vertices.CreateIndexBuffer(pass.GetTransientsBuffer());
  cmd.index_count = vertices.GetIndexCount();
  if (!pass.RecordCommand(std::move(cmd))) {
    return false;
  }
  return true;
}

}  // namespace impeller
