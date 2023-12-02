// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "flutter/impeller/entity/geometry/ellipse_geometry.h"

#include "flutter/impeller/entity/geometry/line_geometry.h"
#include "flutter/impeller/tessellator/circle_tessellator.h"

namespace impeller {

EllipseGeometry::EllipseGeometry(Point center, Scalar radius)
    : center_(center), radius_(radius), stroke_width_(-1.0) {
  FML_DCHECK(radius >= 0);
}

EllipseGeometry::EllipseGeometry(Point center,
                                 Scalar radius,
                                 Scalar stroke_width)
    : center_(center),
      radius_(radius),
      stroke_width_(std::max(stroke_width, 0.0f)) {
  FML_DCHECK(radius >= 0);
  FML_DCHECK(stroke_width >= 0);
}

GeometryResult EllipseGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  using VT = SolidFillVertexShader::PerVertexData;

  Scalar half_width = stroke_width_ < 0
                          ? 0.0
                          : LineGeometry::ComputePixelHalfWidth(
                                entity.GetTransform(), stroke_width_);
  Scalar outer_radius = radius_ + half_width;
  Scalar inner_radius = half_width <= 0 ? 0.0 : radius_ - half_width;

  const Point& center = center_;
  std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
  CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                       outer_radius);

  BufferView vertex_buffer;
  size_t count;
  if (inner_radius > 0) {
    count = circle_tessellator.GetStrokedCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &count, &center, outer_radius,
         inner_radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateStrokedCircleTriangleStrip(
              [&vertices](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                };
              },
              center, outer_radius, inner_radius);
          FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) + count);
        });
  } else {
    count = circle_tessellator.GetCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &count, &center, outer_radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateCircleTriangleStrip(
              [&vertices](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                };
              },
              center, outer_radius);
          FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) + count);
        });
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
GeometryResult EllipseGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  using VT = TextureFillVertexShader::PerVertexData;
  auto uv_transform =
      texture_coverage.GetNormalizingTransform() * effect_transform;

  Scalar half_width = stroke_width_ < 0
                          ? 0.0
                          : LineGeometry::ComputePixelHalfWidth(
                                entity.GetTransform(), stroke_width_);
  Scalar outer_radius = radius_ + half_width;
  Scalar inner_radius = half_width <= 0 ? 0.0 : radius_ - half_width;

  const Point& center = center_;
  std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
  CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                       outer_radius);

  BufferView vertex_buffer;
  size_t count;
  if (inner_radius > 0) {
    count = circle_tessellator.GetStrokedCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &uv_transform, &count, &center, outer_radius,
         inner_radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateStrokedCircleTriangleStrip(
              [&vertices, &uv_transform](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                    .texture_coords = uv_transform * p,
                };
              },
              center, outer_radius, inner_radius);
          FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) + count);
        });
  } else {
    count = circle_tessellator.GetCircleVertexCount();
    vertex_buffer = host_buffer.Emplace(
        count * sizeof(VT), alignof(VT),
        [&circle_tessellator, &uv_transform, &count, &center,
         outer_radius](uint8_t* buffer) {
          auto vertices = reinterpret_cast<VT*>(buffer);
          circle_tessellator.GenerateCircleTriangleStrip(
              [&vertices, &uv_transform](const Point& p) {  //
                *vertices++ = {
                    .position = p,
                    .texture_coords = uv_transform * p,
                };
              },
              center, outer_radius);
          FML_DCHECK(vertices == reinterpret_cast<VT*>(buffer) + count);
        });
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

GeometryVertexType EllipseGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> EllipseGeometry::GetCoverage(
    const Matrix& transform) const {
  Point corners[4]{
      {center_.x, center_.y - radius_},
      {center_.x + radius_, center_.y},
      {center_.x, center_.y + radius_},
      {center_.x - radius_, center_.y},
  };

  for (int i = 0; i < 4; i++) {
    corners[i] = transform * corners[i];
  }
  return Rect::MakePointBounds(std::begin(corners), std::end(corners));
}

bool EllipseGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  return false;
}

bool EllipseGeometry::IsAxisAlignedRect() const {
  return false;
}

}  // namespace impeller
