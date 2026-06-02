// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/path_sdf_contents.h"
#include "flutter/fml/logging.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/tessellator/path_tessellator.h"

namespace impeller {

namespace {
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = PathSdfTestPipeline::VertexShader;
using FS = PathSdfTestPipeline::FragmentShader;

class SleeveVertexWriter : public PathTessellator::VertexWriter {
 public:
  struct Segment {
    Point start;
    Point end;
  };

  void Write(Point point) override {
    if (has_prev_point_) {
      if (prev_point_ != point) {
        segments_.push_back({prev_point_, point});
      }
    }
    prev_point_ = point;
    has_prev_point_ = true;
  }

  void EndContour() override { has_prev_point_ = false; }

  const std::vector<Segment>& GetSegments() const { return segments_; }

 private:
  Point prev_point_;
  bool has_prev_point_ = false;
  std::vector<Segment> segments_;
};

}  // namespace

std::unique_ptr<PathSdfContents> PathSdfContents::Make(
    const flutter::DlPath& path,
    std::unique_ptr<Geometry> geometry,
    Color color,
    Scalar stroke_width) {
  return std::unique_ptr<PathSdfContents>(
      new PathSdfContents(path, std::move(geometry), color, stroke_width));
}

PathSdfContents::PathSdfContents(const flutter::DlPath& path,
                                 std::unique_ptr<Geometry> geometry,
                                 Color color,
                                 Scalar stroke_width)
    : path_(path),
      geometry_(std::move(geometry)),
      color_(color),
      stroke_width_(stroke_width) {}

bool PathSdfContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  Matrix transform = entity.GetTransform();
  Scalar scale = transform.GetMaxBasisLengthXY();
  if (scale < 0.0001f) {
    return true;
  }

  // 1. Flatten path into segments using CPU pruner
  SleeveVertexWriter writer;
  PathTessellator::PathToStrokedVertices(path_, writer, scale);
  const auto& segments = writer.GetSegments();
  if (segments.empty()) {
    return true;
  }

  // 2. Bind uniforms & draw using the default tessellated path mesh
  VS::FrameInfo frame_info;
  frame_info.local_to_device = transform;

  Scalar half_width = stroke_width_ > 0.0f ? stroke_width_ * 0.5f : 0.0f;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.aa_pixels = 1.0f;
  frag_info.half_stroke_width = half_width * scale;

  size_t num_segs = std::min<size_t>(segments.size(), 64);
  frag_info.num_segments = static_cast<Scalar>(num_segs);

  for (size_t i = 0; i < num_segs; ++i) {
    Point A = transform * segments[i].start;
    Point B = transform * segments[i].end;
    frag_info.seg_points[i] = Vector4(A.x, A.y, B.x, B.y);
  }

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

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
        pass.SetCommandLabel("PathSDFSleeve");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [](const ContentContext& renderer, const Entity& entity, RenderPass& pass,
         const Geometry* geometry) {
        return geometry->GetPositionBuffer(renderer, entity, pass);
      });
}

std::optional<Rect> PathSdfContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

const Geometry* PathSdfContents::GetGeometry() const {
  return geometry_.get();
}

}  // namespace impeller
