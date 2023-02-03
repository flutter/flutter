// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
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

void VerticesContents::SetGeometry(std::shared_ptr<VerticesGeometry> geometry) {
  geometry_ = std::move(geometry);
}

void VerticesContents::SetSourceContents(std::shared_ptr<Contents> contents) {
  src_contents_ = std::move(contents);
}

std::shared_ptr<VerticesGeometry> VerticesContents::GetGeometry() const {
  return geometry_;
}

void VerticesContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void VerticesContents::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  if (blend_mode_ == BlendMode::kClear) {
    return true;
  }
  auto dst_contents = std::make_shared<VerticesColorContents>(*this);

  auto contents = ColorFilterContents::MakeBlend(
      blend_mode_, {FilterInput::Make(dst_contents, false),
                    FilterInput::Make(src_contents_, false)});
  contents->SetAlpha(alpha_);

  return contents->Render(renderer, entity, pass);
}

//------------------------------------------------------
// VerticesColorContents

VerticesColorContents::VerticesColorContents(const VerticesContents& parent)
    : parent_(parent) {}

VerticesColorContents::~VerticesColorContents() {}

// |Contents|
std::optional<Rect> VerticesColorContents::GetCoverage(
    const Entity& entity) const {
  return parent_.GetCoverage(entity);
}

void VerticesColorContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

// |Contents|
bool VerticesColorContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  using VS = GeometryColorPipeline::VertexShader;
  using FS = GeometryColorPipeline::FragmentShader;

  Command cmd;
  cmd.label = "VerticesColors";
  auto& host_buffer = pass.GetTransientsBuffer();
  auto geometry = parent_.GetGeometry();

  auto geometry_result =
      geometry->GetPositionColorBuffer(renderer, entity, pass);
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetGeometryColorPipeline(opts);
  cmd.BindVertices(geometry_result.vertex_buffer);

  VS::VertInfo vert_info;
  vert_info.mvp = geometry_result.transform;
  VS::BindVertInfo(cmd, host_buffer.EmplaceUniform(vert_info));

  FS::FragInfo frag_info;
  frag_info.alpha = alpha_;
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));

  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
