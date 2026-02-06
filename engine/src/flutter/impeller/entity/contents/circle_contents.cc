// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/circle_contents.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/geometry/point.h"

namespace impeller {

namespace {
using BindFragmentCallback = std::function<bool(RenderPass& pass)>;
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;
using CreateGeometryCallback =
    std::function<GeometryResult(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 const Geometry* geometry)>;

using VS = CirclePipeline::VertexShader;
using FS = CirclePipeline::FragmentShader;

GeometryResult CreateGeometry(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass,
                              const CircleGeometry* circle_geometry) {
  auto geometry_result =
      circle_geometry->GetPositionBuffer(renderer, entity, pass);
  return geometry_result;
}
}  // namespace

std::unique_ptr<CircleContents> CircleContents::Make(
    std::unique_ptr<CircleGeometry> geometry,
    Color color,
    bool stroked) {
  return std::unique_ptr<CircleContents>(
      new CircleContents(std::move(geometry), color, stroked));
}

CircleContents::CircleContents(std::unique_ptr<CircleGeometry> geometry,
                               Color color,
                               bool stroked)
    : geometry_(std::move(geometry)), color_(color), stroked_(stroked) {}

bool CircleContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = geometry_->GetCenter();
  frag_info.radius = geometry_->GetRadius();
  frag_info.stroke_width = geometry_->GetStrokeWidth();
  frag_info.aa_pixels = 1.0;
  frag_info.stroked = stroked_ ? 1.0f : 0.0f;

  auto geometry_result =
      CreateGeometry(renderer, entity, pass, geometry_.get());

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetCirclePipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("Circle");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result; });
}

std::optional<Rect> CircleContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

}  // namespace impeller
