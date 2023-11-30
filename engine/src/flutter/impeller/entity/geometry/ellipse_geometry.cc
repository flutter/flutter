// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/ellipse_geometry.h"

#include "flutter/impeller/tessellator/circle_tessellator.h"

namespace impeller {

EllipseGeometry::EllipseGeometry(Point center, Scalar radius)
    : center_(center), radius_(radius) {
  FML_DCHECK(radius >= 0);
}

GeometryResult EllipseGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();
  using VT = SolidFillVertexShader::PerVertexData;

  Scalar radius = radius_;
  const Point& center = center_;
  std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
  CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                       radius_);
  size_t count = circle_tessellator.GetCircleVertexCount();
  auto vertex_buffer = host_buffer.Emplace(
      count * sizeof(VT), alignof(VT),
      [&circle_tessellator, &center, radius](uint8_t* buffer) {
        auto vertices = reinterpret_cast<VT*>(buffer);
        circle_tessellator.GenerateCircleTriangleStrip(
            [&vertices](const Point& p) {  //
              *vertices++ = {
                  .position = p,
              };
            },
            center, radius);
      });

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

  Scalar radius = radius_;
  const Point& center = center_;
  std::shared_ptr<Tessellator> tessellator = renderer.GetTessellator();
  CircleTessellator circle_tessellator(tessellator, entity.GetTransform(),
                                       radius_);
  size_t count = circle_tessellator.GetCircleVertexCount();
  auto vertex_buffer = host_buffer.Emplace(
      count * sizeof(VT), alignof(VT),
      [&circle_tessellator, &uv_transform, &center, radius](uint8_t* buffer) {
        auto vertices = reinterpret_cast<VT*>(buffer);
        circle_tessellator.GenerateCircleTriangleStrip(
            [&vertices, &uv_transform](const Point& p) {  //
              *vertices++ = {
                  .position = p,
                  .texture_coords = uv_transform * p,
              };
            },
            center, radius);
      });

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
