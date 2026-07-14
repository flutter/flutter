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
    Color color,
    Scalar stroke_width,
    std::vector<PathSegment> segments) {
  return std::unique_ptr<PathSdfContents>(
      new PathSdfContents(std::move(geometry), color, stroke_width, segments));
}

PathSdfContents::PathSdfContents(std::unique_ptr<Geometry> geometry,
                                 Color color,
                                 Scalar stroke_width,
                                 std::vector<PathSegment> segments)
    : geometry_(std::move(geometry)),
      color_(color),
      stroke_width_(stroke_width),
      segments_(segments) {}

bool PathSdfContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroke_width = stroke_width_;
  frag_info.segment_count = std::min(segments_.size(), static_cast<size_t>(16));
  frag_info.aa_pixels = 1.0f;
  frag_info.unused = 0.0f;

  // Zero out the segments first
  for (size_t i = 0; i < 48; ++i) {
    frag_info.segments[i] = Vector4(0.0f, 0.0f, 0.0f, 0.0f);
  }

  // Pack the active segments
  size_t active_count = static_cast<size_t>(frag_info.segment_count);
  for (size_t i = 0; i < active_count; ++i) {
    const auto& seg = segments_[i];
    frag_info.segments[3 * i + 0] =
        Vector4(seg.p0.x, seg.p0.y, seg.p1.x, seg.p1.y);
    frag_info.segments[3 * i + 1] =
        Vector4(seg.p2.x, seg.p2.y, seg.p3.x, seg.p3.y);
    frag_info.segments[3 * i + 2] = Vector4(seg.type, 0.0f, 0.0f, 0.0f);
  }

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
