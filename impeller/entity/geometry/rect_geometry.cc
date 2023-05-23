// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

RectGeometry::RectGeometry(Rect rect) : rect_(rect) {}

RectGeometry::~RectGeometry() = default;

GeometryResult RectGeometry::GetPositionBuffer(const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass) {
  auto& host_buffer = pass.GetTransientsBuffer();
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = host_buffer.Emplace(
                  rect_.GetPoints().data(), 8 * sizeof(float), alignof(float)),
              .vertex_count = 4,
              .index_type = IndexType::kNone,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult RectGeometry::GetPositionUVBuffer(Rect texture_coverage,
                                                 Matrix effect_transform,
                                                 const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) {
  return ComputeUVGeometryForRect(rect_, texture_coverage, effect_transform,
                                  renderer, entity, pass);
}

GeometryVertexType RectGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> RectGeometry::GetCoverage(const Matrix& transform) const {
  return rect_.TransformBounds(transform);
}

}  // namespace impeller
