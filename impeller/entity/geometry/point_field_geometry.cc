// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/point_field_geometry.h"

#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

PointFieldGeometry::PointFieldGeometry(std::vector<Point> points,
                                       Scalar radius,
                                       bool round)
    : points_(std::move(points)), radius_(radius), round_(round) {}

PointFieldGeometry::~PointFieldGeometry() = default;

GeometryResult PointFieldGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (radius_ < 0.0 || points_.empty()) {
    return {};
  }
  const Matrix& transform = entity.GetTransform();
  Scalar max_basis = transform.GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }

  Scalar min_size = 0.5f / max_basis;
  Scalar radius = std::max(radius_, min_size);
  HostBuffer& host_buffer = renderer.GetTransientsBuffer();
  BufferView buffer_view;
  size_t vertex_count = 0;

  if (round_) {
    // Get triangulation relative to {0, 0} so we can translate it to each
    // point in turn.
    Tessellator::EllipticalVertexGenerator generator =
        renderer.GetTessellator()->FilledCircle(transform, {}, radius);
    FML_DCHECK(generator.GetTriangleType() == PrimitiveType::kTriangleStrip);

    std::vector<Point> circle_vertices;
    circle_vertices.reserve(generator.GetVertexCount());
    generator.GenerateVertices([&circle_vertices](const Point& p) {  //
      circle_vertices.push_back(p);
    });
    FML_DCHECK(circle_vertices.size() == generator.GetVertexCount());

    vertex_count = (circle_vertices.size() + 2) * points_.size() - 2;
    buffer_view = host_buffer.Emplace(
        vertex_count * sizeof(Point), alignof(Point), [&](uint8_t* data) {
          Point* output = reinterpret_cast<Point*>(data);
          size_t offset = 0;

          Point center = points_[0];
          for (auto& vertex : circle_vertices) {
            output[offset++] = Point(center + vertex);
          }
          // For all subequent points, insert a degenerate triangle to break
          // the strip. This could be optimized out if we switched to using
          // primitive restart.
          Point last_point = circle_vertices.back() + center;
          for (size_t i = 1; i < points_.size(); i++) {
            Point center = points_[i];
            output[offset++] = last_point;
            output[offset++] = Point(center + circle_vertices[0]);
            for (const Point& vertex : circle_vertices) {
              output[offset++] = Point(center + vertex);
            }
            last_point = circle_vertices.back() + center;
          }
        });
  } else {
    vertex_count = 6 * points_.size() - 2;
    buffer_view = host_buffer.Emplace(
        vertex_count * sizeof(Point), alignof(Point), [&](uint8_t* data) {
          Point* output = reinterpret_cast<Point*>(data);
          size_t offset = 0;

          Point point = points_[0];
          Point first = Point(point.x - radius, point.y - radius);

          // Z pattern from UL -> UR -> LL -> LR
          Point last_point = Point(0, 0);
          output[offset++] = first;
          output[offset++] = Point(point.x + radius, point.y - radius);
          output[offset++] = Point(point.x - radius, point.y + radius);
          output[offset++] = last_point =
              Point(point.x + radius, point.y + radius);

          // For all subequent points, insert a degenerate triangle to break
          // the strip. This could be optimized out if we switched to using
          // primitive restart.
          for (size_t i = 1; i < points_.size(); i++) {
            Point point = points_[i];
            Point first = Point(point.x - radius, point.y - radius);

            output[offset++] = last_point;
            output[offset++] = first;

            output[offset++] = first;
            output[offset++] = Point(point.x + radius, point.y - radius);
            output[offset++] = Point(point.x - radius, point.y + radius);
            output[offset++] = last_point =
                Point(point.x + radius, point.y + radius);
          }
        });
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          VertexBuffer{
              .vertex_buffer = std::move(buffer_view),
              .index_buffer = {},
              .vertex_count = vertex_count,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}

// |Geometry|
std::optional<Rect> PointFieldGeometry::GetCoverage(
    const Matrix& transform) const {
  if (points_.size() > 0) {
    // Doesn't use MakePointBounds as this isn't resilient to points that
    // all lie along the same axis.
    auto first = points_.begin();
    auto last = points_.end();
    auto left = first->x;
    auto top = first->y;
    auto right = first->x;
    auto bottom = first->y;
    for (auto it = first + 1; it < last; ++it) {
      left = std::min(left, it->x);
      top = std::min(top, it->y);
      right = std::max(right, it->x);
      bottom = std::max(bottom, it->y);
    }
    auto coverage = Rect::MakeLTRB(left - radius_, top - radius_,
                                   right + radius_, bottom + radius_);
    return coverage.TransformBounds(transform);
  }
  return std::nullopt;
}

}  // namespace impeller
