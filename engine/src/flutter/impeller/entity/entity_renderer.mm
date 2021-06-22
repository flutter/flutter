// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_renderer.h"

#include "impeller/compositor/command.h"
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

  is_valid_ = true;
}

EntityRenderer::~EntityRenderer() = default;

bool EntityRenderer::OnIsValid() const {
  return is_valid_;
}

bool EntityRenderer::OnRender(RenderPass& pass) {
  pass.SetLabel("EntityRenderer");

  shader::BoxVertexInfo::UniformBuffer uniforms;
  uniforms.mvp = Matrix::MakeOrthographic({800, 600});
  VertexBufferBuilder vertex_builder;
  vertex_builder.AddVertices({
      {-0.5, 0.5, 1.0},   //
      {0.5, 0.5, 1.0},    //
      {0.5, -0.5, 1.0},   //
      {0.5, -0.5, 1.0},   //
      {-0.5, -0.5, 1.0},  //
      {-0.5, 0.5, 1.0},   //
  });

  Command cmd;
  cmd.label = "Box";
  cmd.pipeline = box_primitive_->GetPipeline();
  cmd.vertex_bindings.buffers[0u] =
      vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer());
  cmd.vertex_bindings.buffers[1u] =
      pass.GetTransientsBuffer().EmplaceUniform(uniforms);
  cmd.index_buffer =
      vertex_builder.CreateIndexBuffer(pass.GetTransientsBuffer());
  cmd.index_count = vertex_builder.GetIndexCount();
  cmd.primitive_type = PrimitiveType::kTriange;
  if (!pass.RecordCommand(std::move(cmd))) {
    return false;
  }
  return true;
}

}  // namespace impeller
