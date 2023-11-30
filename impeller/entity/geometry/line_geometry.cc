// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/line_geometry.h"

#include "flutter/impeller/tessellator/circle_tessellator.h"

namespace impeller {

LineGeometry::LineGeometry(Point p0, Point p1, Scalar width, Cap cap)
    : p0_(p0), p1_(p1), width_(width), cap_(cap) {
  FML_DCHECK(width >= 0);
}

Scalar LineGeometry::ComputeHalfWidth(const Matrix& transform) const {
  auto determinant = transform.GetDeterminant();
  if (determinant == 0) {
    return 0.0f;
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  return std::max(width_, min_size) * 0.5f;
}

Vector2 LineGeometry::ComputeAlongVector(const Matrix& transform,
                                         bool allow_zero_length) const {
  Scalar stroke_half_width = ComputeHalfWidth(transform);
  if (stroke_half_width < kEhCloseEnough) {
    return {};
  }

  auto along = p1_ - p0_;
  Scalar length = along.GetLength();
  if (length < kEhCloseEnough) {
    if (!allow_zero_length) {
      // We won't enclose any pixels unless the endpoints are extended
      return {};
    }
    return {stroke_half_width, 0};
  } else {
    return along * stroke_half_width / length;
  }
}

bool LineGeometry::ComputeCorners(Point corners[4],
                                  const Matrix& transform,
                                  bool extend_endpoints) const {
  auto along = ComputeAlongVector(transform, extend_endpoints);
  if (along.IsZero()) {
    return false;
  }

  auto across = Vector2(along.y, -along.x);
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
                                               RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  using VT = SolidFillVertexShader::PerVertexData;

  auto& transform = entity.GetTransform();
  auto radius = ComputeHalfWidth(transform);

  size_t count;
  BufferView vertex_buffer;
  if (cap_ == Cap::kRound) {
    const Point& p0 = p0_;
    const Point& p1 = p1_;

    std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
    CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                         radius);
    count = circle_tessellator.GetCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &p0, &p1, radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateRoundCapLineTriangleStrip(
              [&vertices](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                };
              },
              p0, p1, radius);
        });
  } else {
    Point corners[4];
    if (ComputeCorners(corners, transform, cap_ == Cap::kSquare)) {
      count = 4;
      vertex_buffer = host_buffer.Emplace(
          count * sizeof(VT), alignof(VT), [&corners](uint8_t* buffer) {
            auto vertices = reinterpret_cast<VT*>(buffer);
            for (auto& corner : corners) {
              *vertices++ = {
                  .position = corner,
              };
            }
          });
    } else {
      return {};
    }
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = vertex_buffer,
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransform(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult LineGeometry::GetPositionUVBuffer(Rect texture_coverage,
                                                 Matrix effect_transform,
                                                 const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  using VT = TextureFillVertexShader::PerVertexData;

  auto& transform = entity.GetTransform();
  auto radius = ComputeHalfWidth(transform);

  auto uv_transform =
      texture_coverage.GetNormalizingTransform() * effect_transform;

  size_t count;
  BufferView vertex_buffer;
  if (cap_ == Cap::kRound) {
    const Point& p0 = p0_;
    const Point& p1 = p1_;

    std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
    CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                         radius);
    count = circle_tessellator.GetCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &uv_transform, &p0, &p1,
         radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateRoundCapLineTriangleStrip(
              [&vertices, &uv_transform](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                    .texture_coords = uv_transform * p,
                };
              },
              p0, p1, radius);
        });
  } else {
    Point corners[4];
    if (ComputeCorners(corners, transform, cap_ == Cap::kSquare)) {
      count = 4;
      vertex_buffer =
          host_buffer.Emplace(count * sizeof(VT), alignof(VT),
                              [&uv_transform, &corners](uint8_t* buffer) {
                                auto vertices = reinterpret_cast<VT*>(buffer);
                                for (auto& corner : corners) {
                                  *vertices++ = {
                                      .position = corner,
                                      .texture_coords = uv_transform * corner,
                                  };
                                }
                              });
    } else {
      return {};
    }
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = vertex_buffer,
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransform(),
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
  return cap_ != Cap::kRound && (p0_.x == p1_.x || p0_.y == p1_.y);
}

}  // namespace impeller
