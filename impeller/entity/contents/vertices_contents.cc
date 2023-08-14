// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

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

const std::shared_ptr<Contents>& VerticesContents::GetSourceContents() const {
  return src_contents_;
}

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  if (blend_mode_ == BlendMode::kClear) {
    return true;
  }
  std::shared_ptr<Contents> src_contents = src_contents_;
  src_contents->SetCoverageHint(GetCoverageHint());
  if (geometry_->HasTextureCoordinates()) {
    auto contents = std::make_shared<VerticesUVContents>(*this);
    contents->SetCoverageHint(GetCoverageHint());
    if (!geometry_->HasVertexColors()) {
      contents->SetAlpha(alpha_);
      return contents->Render(renderer, entity, pass);
    }
    src_contents = contents;
  }

  auto dst_contents = std::make_shared<VerticesColorContents>(*this);
  dst_contents->SetCoverageHint(GetCoverageHint());

  std::shared_ptr<Contents> contents;
  if (blend_mode_ == BlendMode::kDestination) {
    contents = dst_contents;
  } else {
    auto color_filter_contents = ColorFilterContents::MakeBlend(
        blend_mode_, {FilterInput::Make(dst_contents, false),
                      FilterInput::Make(src_contents, false)});
    color_filter_contents->SetAlpha(alpha_);
    color_filter_contents->SetCoverageHint(GetCoverageHint());
    contents = color_filter_contents;
  }

  FML_DCHECK(contents->GetCoverageHint() == GetCoverageHint());
  return contents->Render(renderer, entity, pass);
}

//------------------------------------------------------
// VerticesUVContents

VerticesUVContents::VerticesUVContents(const VerticesContents& parent)
    : parent_(parent) {}

VerticesUVContents::~VerticesUVContents() {}

std::optional<Rect> VerticesUVContents::GetCoverage(
    const Entity& entity) const {
  return parent_.GetCoverage(entity);
}

void VerticesUVContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

bool VerticesUVContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  using VS = TexturePipeline::VertexShader;
  using FS = TexturePipeline::FragmentShader;

  auto src_contents = parent_.GetSourceContents();

  auto snapshot =
      src_contents->RenderToSnapshot(renderer,           // renderer
                                     entity,             // entity
                                     GetCoverageHint(),  // coverage_limit
                                     std::nullopt,       // sampler_descriptor
                                     true,               // msaa_enabled
                                     "VerticesUVContents Snapshot");  // label
  if (!snapshot.has_value()) {
    return false;
  }

  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "VerticesUV");
  auto& host_buffer = pass.GetTransientsBuffer();
  auto geometry = parent_.GetGeometry();

  auto coverage = src_contents->GetCoverage(Entity{});
  if (!coverage.has_value()) {
    return false;
  }
  auto geometry_result = geometry->GetPositionUVBuffer(
      coverage.value(), Matrix(), renderer, entity, pass);
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetTexturePipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(geometry_result.vertex_buffer);

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  frame_info.texture_sampler_y_coord_scale =
      snapshot->texture->GetYCoordScale();
  frame_info.alpha = alpha_ * snapshot->opacity;
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

  FS::BindTextureSampler(cmd, snapshot->texture,
                         renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                             snapshot->sampler_descriptor));

  return pass.AddCommand(std::move(cmd));
}

//------------------------------------------------------
// VerticesColorContents

VerticesColorContents::VerticesColorContents(const VerticesContents& parent)
    : parent_(parent) {}

VerticesColorContents::~VerticesColorContents() {}

std::optional<Rect> VerticesColorContents::GetCoverage(
    const Entity& entity) const {
  return parent_.GetCoverage(entity);
}

void VerticesColorContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

bool VerticesColorContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  using VS = GeometryColorPipeline::VertexShader;
  using FS = GeometryColorPipeline::FragmentShader;

  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "VerticesColors");
  auto& host_buffer = pass.GetTransientsBuffer();
  auto geometry = parent_.GetGeometry();

  auto geometry_result =
      geometry->GetPositionColorBuffer(renderer, entity, pass);
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetGeometryColorPipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(geometry_result.vertex_buffer);

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

  FS::FragInfo frag_info;
  frag_info.alpha = alpha_;
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));

  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
