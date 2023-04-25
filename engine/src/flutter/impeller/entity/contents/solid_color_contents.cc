// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "solid_color_contents.h"

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

SolidColorContents::SolidColorContents() = default;

SolidColorContents::~SolidColorContents() = default;

void SolidColorContents::SetColor(Color color) {
  color_ = color;
}

Color SolidColorContents::GetColor() const {
  return color_.WithAlpha(color_.alpha * GetOpacity());
}

std::optional<Rect> SolidColorContents::GetCoverage(
    const Entity& entity) const {
  if (GetColor().IsTransparent()) {
    return std::nullopt;
  }

  auto geometry = GetGeometry();
  if (geometry == nullptr) {
    return std::nullopt;
  }
  return geometry->GetCoverage(entity.GetTransformation());
};

bool SolidColorContents::ShouldRender(
    const Entity& entity,
    const std::optional<Rect>& stencil_coverage) const {
  if (!stencil_coverage.has_value()) {
    return false;
  }
  return Contents::ShouldRender(entity, stencil_coverage);
}

bool SolidColorContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  using VS = SolidFillPipeline::VertexShader;
  using FS = SolidFillPipeline::FragmentShader;

  Command cmd;
  cmd.label = "Solid Fill";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }

  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetSolidFillPipeline(options);
  cmd.BindVertices(geometry_result.vertex_buffer);

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  FS::FragInfo frag_info;
  frag_info.color = GetColor().Premultiply();
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  if (geometry_result.prevent_overdraw) {
    auto restore = ClipRestoreContents();
    restore.SetRestoreCoverage(GetCoverage(entity));
    return restore.Render(renderer, entity, pass);
  }
  return true;
}

std::unique_ptr<SolidColorContents> SolidColorContents::Make(const Path& path,
                                                             Color color) {
  auto contents = std::make_unique<SolidColorContents>();
  contents->SetGeometry(Geometry::MakeFillPath(path));
  contents->SetColor(color);
  return contents;
}

}  // namespace impeller
