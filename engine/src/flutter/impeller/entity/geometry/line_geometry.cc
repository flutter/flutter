// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/line_geometry.h"

namespace impeller {

LineGeometry::LineGeometry(Point p0, Point p1, Scalar width, Cap cap)
    : p0_(p0), p1_(p1), width_(width), cap_(cap) {
  // Some of the code below is prepared to deal with things like coverage
  // of a line with round caps, but more work is needed to deal with drawing
  // the round end caps
  FML_DCHECK(width >= 0);
  FML_DCHECK(cap != Cap::kRound);
}

LineGeometry::~LineGeometry() = default;

bool LineGeometry::ComputeCorners(Point corners[4],
                                  const Matrix& transform,
                                  bool extend_endpoints) const {
  auto determinant = transform.GetDeterminant();
  if (determinant == 0) {
    return false;
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar stroke_half_width = std::max(width_, min_size) * 0.5f;

  Point along = p1_ - p0_;
  Scalar length = along.GetLength();
  if (length < kEhCloseEnough) {
    if (!extend_endpoints) {
      // We won't enclose any pixels unless the endpoints are extended
      return false;
    }
    along = {stroke_half_width, 0};
  } else {
    along *= stroke_half_width / length;
  }
  Point across = {along.y, -along.x};
  corners[0] = p0_ - across;
  corners[1] = p1_ - across;
  corners[2] = p0_ + across;
  corners[3] = p1_ + across;
  if (extend_endpoints) {
    corners[0] -= along;
    corners[1] += along;
    corners[2] -= along;
    corners[3] += along;
  }
  return true;
}

GeometryResult LineGeometry::GetPositionBuffer(const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass) {
  auto& host_buffer = pass.GetTransientsBuffer();

  Point corners[4];
  if (!ComputeCorners(corners, entity.GetTransformation(),
                      cap_ == Cap::kSquare)) {
    return {};
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(corners, 8 * sizeof(float),
                                                   alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult LineGeometry::GetPositionUVBuffer(Rect texture_coverage,
                                                 Matrix effect_transform,
                                                 const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) {
  auto& host_buffer = pass.GetTransientsBuffer();

  auto uv_transform =
      texture_coverage.GetNormalizingTransform() * effect_transform;
  Point corners[4];
  if (!ComputeCorners(corners, entity.GetTransformation(),
                      cap_ == Cap::kSquare)) {
    return {};
  }

  std::vector<Point> data(8);
  for (auto i = 0u, j = 0u; i < 8; i += 2, j++) {
    data[i] = corners[j];
    data[i + 1] = uv_transform * corners[j];
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  data.data(), 16 * sizeof(float), alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryVertexType LineGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> LineGeometry::GetCoverage(const Matrix& transform) const {
  Point corners[4];
  if (!ComputeCorners(corners, transform, cap_ != Cap::kButt)) {
    return {};
  }

  for (int i = 0; i < 4; i++) {
    corners[i] = transform * corners[i];
  }
  return Rect::MakePointBounds(std::begin(corners), std::end(corners));
}

bool LineGeometry::CoversArea(const Matrix& transform, const Rect& rect) const {
  if (!transform.IsTranslationScaleOnly() || !IsAxisAlignedRect()) {
    return false;
  }
  auto coverage = GetCoverage(transform);
  return coverage.has_value() ? coverage->Contains(rect) : false;
}

bool LineGeometry::IsAxisAlignedRect() const {
  return p0_.x == p1_.x || p0_.y == p1_.y;
}

}  // namespace impeller
