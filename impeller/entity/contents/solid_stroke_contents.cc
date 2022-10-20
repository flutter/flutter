// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "solid_stroke_contents.h"

#include <optional>

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/solid_fill.frag.h"
#include "impeller/entity/solid_fill.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

SolidStrokeContents::SolidStrokeContents(){};

SolidStrokeContents::~SolidStrokeContents() = default;

void SolidStrokeContents::SetColor(Color color) {
  color_ = color;
}

const Color& SolidStrokeContents::GetColor() const {
  return color_;
}

void SolidStrokeContents::SetGeometry(std::unique_ptr<Geometry> geometry) {
  geometry_ = std::move(geometry);
}

std::optional<Rect> SolidStrokeContents::GetCoverage(
    const Entity& entity) const {
  if (color_.IsTransparent()) {
    return std::nullopt;
  }
  return geometry_->GetCoverage(entity.GetTransformation());
}

bool SolidStrokeContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  using VS = SolidFillVertexShader;
  using FS = SolidFillFragmentShader;
  VS::VertInfo vert_info;
  vert_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                  entity.GetTransformation();

  FS::FragInfo frag_info;
  frag_info.color = color_.Premultiply();

  Command cmd;
  cmd.label = "Solid Stroke";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto geometry_result = geometry_->GetPositionBuffer(renderer, entity, pass);

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  cmd.pipeline = renderer.GetSolidFillPipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  cmd.primitive_type = geometry_result.type;
  VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(vert_info));
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  pass.AddCommand(cmd);

  if (geometry_result.prevent_overdraw) {
    return ClipRestoreContents().Render(renderer, entity, pass);
  }

  return true;
}

}  // namespace impeller
