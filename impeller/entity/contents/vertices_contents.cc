// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/position.vert.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/entity/position_uv.vert.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

VerticesContents::VerticesContents() = default;

VerticesContents::~VerticesContents() = default;

std::optional<Rect> VerticesContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransformation());
};

void VerticesContents::SetGeometry(std::unique_ptr<VerticesGeometry> geometry) {
  geometry_ = std::move(geometry);
}

void VerticesContents::SetColor(Color color) {
  color_ = color.Premultiply();
}

void VerticesContents::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  auto vertex_type = geometry_->GetVertexType();

  Command cmd;
  cmd.label = "Vertices";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto opts = OptionsFromPassAndEntity(pass, entity);

  switch (vertex_type) {
    case GeometryVertexType::kColor: {
      using VS = GeometryColorPipeline::VertexShader;

      auto geometry_result = geometry_->GetPositionColorBuffer(
          renderer, entity, pass, color_, blend_mode_);
      opts.primitive_type = geometry_result.type;
      cmd.pipeline = renderer.GetGeometryColorPipeline(opts);
      cmd.BindVertices(geometry_result.vertex_buffer);

      VS::VertInfo vert_info;
      vert_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                      entity.GetTransformation();
      VS::BindVertInfo(cmd, host_buffer.EmplaceUniform(vert_info));
      break;
    }
    case GeometryVertexType::kUV:
    case GeometryVertexType::kPosition: {
      using VS = GeometryPositionPipeline::VertexShader;

      auto geometry_result =
          geometry_->GetPositionBuffer(renderer, entity, pass);
      opts.primitive_type = geometry_result.type;
      cmd.pipeline = renderer.GetGeometryPositionPipeline(opts);
      cmd.BindVertices(geometry_result.vertex_buffer);

      VS::VertInfo vert_info;
      vert_info.mvp = geometry_result.transform;
      vert_info.color = color_.Premultiply();
      VS::BindVertInfo(cmd,
                       pass.GetTransientsBuffer().EmplaceUniform(vert_info));
      break;
    }
  }
  using FS = GeometryColorPipeline::FragmentShader;
  FS::FragInfo frag_info;
  frag_info.alpha = 1.0;
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  pass.AddCommand(std::move(cmd));

  return true;
}

}  // namespace impeller
