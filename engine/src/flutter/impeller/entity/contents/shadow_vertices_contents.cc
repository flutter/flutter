// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "shadow_vertices_contents.h"

#include <format>

#include "fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/vertices_geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

//------------------------------------------------------
// ShadowVerticesContents

ShadowVerticesContents::ShadowVerticesContents(
    const std::shared_ptr<ShadowVertices>& geometry)
    : geometry_(geometry) {}

ShadowVerticesContents::~ShadowVerticesContents() {}

std::shared_ptr<ShadowVerticesContents> ShadowVerticesContents::Make(
    const std::shared_ptr<ShadowVertices>& geometry) {
  return std::make_shared<ShadowVerticesContents>(geometry);
}

std::optional<Rect> ShadowVerticesContents::GetCoverage(
    const Entity& entity) const {
  return geometry_->GetBounds();
}

void ShadowVerticesContents::SetColor(Color color) {
  shadow_color_ = color;
}

bool ShadowVerticesContents::Render(const ContentContext& renderer,
                                    const Entity& entity,
                                    RenderPass& pass) const {
  using VS = ShadowVerticesVertexShader;
  using FS = ShadowVerticesFragmentShader;

  GeometryResult geometry_result =
      geometry_->GetPositionBuffer(renderer, entity, pass);
  if (geometry_result.vertex_buffer.vertex_count == 0) {
    return true;
  }
  FML_DCHECK(geometry_result.mode == GeometryResult::Mode::kNormal);

#ifdef IMPELLER_DEBUG
  pass.SetCommandLabel("DrawShadow VertexMesh");
#endif  // IMPELLER_DEBUG

  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));

  auto options = OptionsFromPassAndEntity(pass, entity);
  options.primitive_type = geometry_result.type;
  pass.SetPipeline(renderer.GetDrawShadowVerticesPipeline(options));

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;

  frame_info.mvp = entity.GetShaderTransform(pass);

  frag_info.shadow_color = shadow_color_.Premultiply();

  auto& host_buffer = renderer.GetTransientsDataBuffer();
  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
  VS::BindFrameInfo(pass, host_buffer.EmplaceUniform(frame_info));

  return pass.Draw().ok();
}

}  // namespace impeller
