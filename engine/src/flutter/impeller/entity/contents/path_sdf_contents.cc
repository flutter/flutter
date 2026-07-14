// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/path_sdf_contents.h"

#include <cmath>
#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
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

struct SdfVertex {
  Point position;
  Scalar sdf;
};

class SdfSegmentReceiver : public PathTessellator::SegmentReceiver {
 public:
  struct Segment {
    Point start;
    Point end;
  };

  SdfSegmentReceiver(Scalar scale, Scalar half_stroke_width)
      : stroke_scale_(scale * std::max(1.0f, half_stroke_width)) {}

  void BeginContour(Point origin, bool will_be_closed) override {
    prev_point_ = origin;
  }

  void RecordLine(Point p1, Point p2) override {
    if (p1 != p2) {
      segments_.push_back({p1, p2});
    }
    prev_point_ = p2;
  }

  void RecordQuad(Point p1, Point cp, Point p2) override {
    PathTessellator::Quad curve{p1, cp, p2};
    Scalar count =
        std::max(1.0f, std::ceilf(curve.SubdivisionCount(stroke_scale_)));
    Point prev = p1;
    for (int i = 1; i <= count; ++i) {
      Scalar t = static_cast<Scalar>(i) / count;
      Point pt = curve.Solve(t);
      RecordLine(prev, pt);
      prev = pt;
    }
  }

  void RecordConic(Point p1, Point cp, Point p2, Scalar weight) override {
    PathTessellator::Conic curve{p1, cp, p2, weight};
    Scalar count =
        std::max(1.0f, std::ceilf(curve.SubdivisionCount(stroke_scale_)));
    Point prev = p1;
    for (int i = 1; i <= count; ++i) {
      Scalar t = static_cast<Scalar>(i) / count;
      Point pt = curve.Solve(t);
      RecordLine(prev, pt);
      prev = pt;
    }
  }

  void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) override {
    PathTessellator::Cubic curve{p1, cp1, cp2, p2};
    Scalar count =
        std::max(1.0f, std::ceilf(curve.SubdivisionCount(stroke_scale_)));
    Point prev = p1;
    for (int i = 1; i <= count; ++i) {
      Scalar t = static_cast<Scalar>(i) / count;
      Point pt = curve.Solve(t);
      RecordLine(prev, pt);
      prev = pt;
    }
  }

  void EndContour(Point origin, bool with_close) override {
    if (with_close && prev_point_ != origin) {
      RecordLine(prev_point_, origin);
    }
  }

  const std::vector<Segment>& GetSegments() const { return segments_; }

 private:
  Scalar stroke_scale_;
  Point prev_point_;
  std::vector<Segment> segments_;
};

// Draw a round cap centered at 'center' sweeping 180 degrees.
void DrawRoundCap(std::vector<SdfVertex>& vertices,
                  std::vector<uint16_t>& indices,
                  Point center,
                  Point normal,
                  Point tangent,
                  Scalar H,
                  Scalar scale,
                  bool is_start) {
  uint16_t center_idx = vertices.size();
  vertices.push_back({center, 0.0f});

  uint16_t first_boundary_idx = vertices.size();

  Scalar start_angle = is_start ? std::atan2(-normal.y, -normal.x)
                                : std::atan2(normal.y, normal.x);
  Scalar sweep_angle = is_start ? -M_PI : M_PI;

  // Dynamic steps based on screen-space radius to ensure perfect smoothness
  Scalar screen_radius = H * scale;
  int steps = std::clamp<int>(
      static_cast<int>(std::ceil(screen_radius * M_PI / 2.0f)), 8, 64);

  for (int j = 0; j <= steps; ++j) {
    Scalar t = static_cast<Scalar>(j) / steps;
    Scalar angle = start_angle + t * sweep_angle;

    Point rotated_normal(std::cos(angle), std::sin(angle));
    Point P = center + H * rotated_normal;
    vertices.push_back({P, H});
  }

  for (int j = 0; j < steps; ++j) {
    indices.push_back(center_idx);
    indices.push_back(first_boundary_idx + j);
    indices.push_back(first_boundary_idx + j + 1);
  }
}

// Draw a round join centered at 'center' sweeping between start_normal and
// end_normal.
void DrawRoundJoin(std::vector<SdfVertex>& vertices,
                   std::vector<uint16_t>& indices,
                   Point center,
                   Point start_normal,
                   Point end_normal,
                   Scalar H,
                   Scalar scale) {
  uint16_t center_idx = vertices.size();
  vertices.push_back({center, 0.0f});

  uint16_t first_boundary_idx = vertices.size();

  Scalar start_angle = std::atan2(start_normal.y, start_normal.x);
  Scalar end_angle = std::atan2(end_normal.y, end_normal.x);

  Scalar sweep_angle = end_angle - start_angle;
  if (sweep_angle > M_PI) {
    sweep_angle -= 2.0f * M_PI;
  } else if (sweep_angle < -M_PI) {
    sweep_angle += 2.0f * M_PI;
  }

  // Dynamic steps based on screen-space radius and sweep angle to ensure
  // perfect smoothness
  Scalar screen_radius = H * scale;
  int steps = std::clamp<int>(
      static_cast<int>(std::ceil(screen_radius * std::abs(sweep_angle))), 6,
      48);

  for (int j = 0; j <= steps; ++j) {
    Scalar t = static_cast<Scalar>(j) / steps;
    Scalar angle = start_angle + t * sweep_angle;

    Point rotated_normal(std::cos(angle), std::sin(angle));
    Point P = center + H * rotated_normal;
    vertices.push_back({P, H});
  }

  for (int j = 0; j < steps; ++j) {
    indices.push_back(center_idx);
    indices.push_back(first_boundary_idx + j);
    indices.push_back(first_boundary_idx + j + 1);
  }
}

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

  Scalar half_width = stroke_width_ > 0.0f ? stroke_width_ * 0.5f : 0.0f;
  // Sleeve padding: H = half_width + 1.5 screen pixels
  Scalar H = half_width + 1.5f;

  // 1. Flatten path into segments on the CPU using dynamic subdivision based on
  // scale and curvature
  SdfSegmentReceiver receiver(scale, half_width);
  PathTessellator::PathToStrokedSegments(path_, receiver);
  const auto& segments = receiver.GetSegments();
  if (segments.empty()) {
    return true;
  }

  // 2. Prepare tangents and normals
  struct PreparedSegment {
    Point A;
    Point B;
    Point T;
    Point N;
  };
  std::vector<PreparedSegment> prepared;
  prepared.reserve(segments.size());

  for (const auto& seg : segments) {
    Point diff = seg.end - seg.start;
    Scalar len = std::sqrt(diff.x * diff.x + diff.y * diff.y);
    if (len < 0.0001f) {
      continue;
    }
    Point T = diff / len;
    Point N = Point(-T.y, T.x);
    prepared.push_back({seg.start, seg.end, T, N});
  }

  if (prepared.empty()) {
    return true;
  }

  std::vector<SdfVertex> vertices;
  std::vector<uint16_t> indices;

  // 3. Draw Double-Quads (Stroke Body)
  for (size_t i = 0; i < prepared.size(); ++i) {
    const auto& seg = prepared[i];
    Point A = seg.A;
    Point B = seg.B;
    Point N = seg.N;

    Point v0 = A;
    Point v1 = B;
    Point v2 = A - H * N;
    Point v3 = B - H * N;
    Point v4 = A + H * N;
    Point v5 = B + H * N;

    uint16_t start_idx = vertices.size();

    vertices.push_back({v0, 0.0f});
    vertices.push_back({v1, 0.0f});
    vertices.push_back({v2, H});
    vertices.push_back({v3, H});
    vertices.push_back({v4, H});
    vertices.push_back({v5, H});

    // Left quad: v0, v2, v1 and v2, v3, v1
    indices.push_back(start_idx + 0);
    indices.push_back(start_idx + 2);
    indices.push_back(start_idx + 1);

    indices.push_back(start_idx + 2);
    indices.push_back(start_idx + 3);
    indices.push_back(start_idx + 1);

    // Right quad: v0, v1, v4 and v1, v5, v4
    indices.push_back(start_idx + 0);
    indices.push_back(start_idx + 1);
    indices.push_back(start_idx + 4);

    indices.push_back(start_idx + 1);
    indices.push_back(start_idx + 5);
    indices.push_back(start_idx + 4);
  }

  // 4. Draw Start Cap
  DrawRoundCap(vertices, indices, prepared.front().A, prepared.front().N,
               prepared.front().T, H, scale, /*is_start=*/true);

  // 5. Draw End Cap
  DrawRoundCap(vertices, indices, prepared.back().B, prepared.back().N,
               prepared.back().T, H, scale, /*is_start=*/false);

  // 6. Draw Joins between consecutive segments
  for (size_t i = 0; i < prepared.size() - 1; ++i) {
    Point B = prepared[i].B;
    Point T1 = prepared[i].T;
    Point N1 = prepared[i].N;
    Point T2 = prepared[i + 1].T;
    Point N2 = prepared[i + 1].N;

    Scalar cross = T1.x * T2.y - T1.y * T2.x;
    if (cross > 0.0001f) {
      // Clockwise turn: sweep outer left side (from -N1 to -N2)
      DrawRoundJoin(vertices, indices, B, -N1, -N2, H, scale);
    } else if (cross < -0.0001f) {
      // Counter-clockwise turn: sweep outer right side (from +N1 to +N2)
      DrawRoundJoin(vertices, indices, B, N1, N2, H, scale);
    }
  }

  if (vertices.empty()) {
    return true;
  }

  // 7. Bind uniforms & draw
  VS::FrameInfo frame_info;
  frame_info.mvp = entity.GetTransform();

  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.aa_pixels = 1.0f;
  frag_info.half_stroke_width = half_width;

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetPathSdfTestPipeline(options);
      };

  auto vertices_ptr =
      std::make_shared<std::vector<SdfVertex>>(std::move(vertices));
  auto indices_ptr =
      std::make_shared<std::vector<uint16_t>>(std::move(indices));

  ColorSourceContents::CreateGeometryCallback create_geom_callback =
      [vertices_ptr, indices_ptr, &data_host_buffer](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass, const Geometry* geometry) -> GeometryResult {
    BufferView buffer_view = data_host_buffer.Emplace(
        vertices_ptr->data(), vertices_ptr->size() * sizeof(SdfVertex),
        alignof(SdfVertex));
    BufferView index_view = data_host_buffer.Emplace(
        indices_ptr->data(), indices_ptr->size() * sizeof(uint16_t),
        alignof(uint16_t));

    return GeometryResult{.type = PrimitiveType::kTriangle,
                          .vertex_buffer =
                              {
                                  .vertex_buffer = buffer_view,
                                  .index_buffer = index_view,
                                  .vertex_count = indices_ptr->size(),
                                  .index_type = IndexType::k16bit,
                              },
                          .transform = entity.GetShaderTransform(pass),
                          .mode = GeometryResult::Mode::kNormal};
  };

  return ColorSourceContents::DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("PathSDFScalarVertexAttributes");
        return true;
      },
      /*force_stencil=*/false, create_geom_callback);
}

std::optional<Rect> PathSdfContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

const Geometry* PathSdfContents::GetGeometry() const {
  return geometry_.get();
}

}  // namespace impeller
