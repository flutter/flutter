// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/path_sdf_contents.h"
#include "flutter/fml/logging.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/point.h"

namespace impeller {

namespace {
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = PathSdfTestPipeline::VertexShader;
using FS = PathSdfTestPipeline::FragmentShader;

}  // namespace

std::unique_ptr<PathSdfContents> PathSdfContents::Make(
    std::unique_ptr<Geometry> geometry,
    Color color) {
  return std::unique_ptr<PathSdfContents>(
      new PathSdfContents(std::move(geometry), color));
}

PathSdfContents::PathSdfContents(std::unique_ptr<Geometry> geometry,
                                 Color color)
    : geometry_(std::move(geometry)),
      color_(color) {}

bool PathSdfContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  FML_LOG(IMPORTANT) << "PathSdfContents::Render executing";
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());

  auto geometry_result = geometry_->GetPositionBuffer(renderer, entity, pass);

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetPathSdfTestPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FML_LOG(IMPORTANT) << "PathSdfContents::Render bind_fragment_callback binding uniforms";
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("PathSDF");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result; });
}

std::optional<Rect> PathSdfContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

const Geometry* PathSdfContents::GetGeometry() const {
  return geometry_.get();
}

}  // namespace impeller
