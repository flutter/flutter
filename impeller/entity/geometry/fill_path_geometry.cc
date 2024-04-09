// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/fill_path_geometry.h"

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

FillPathGeometry::FillPathGeometry(const Path& path,
                                   std::optional<Rect> inner_rect)
    : path_(path), inner_rect_(inner_rect) {}

GeometryResult FillPathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = renderer.GetTransientsBuffer();

  const auto& bounding_box = path_.GetBoundingBox();
  if (bounding_box.has_value() && bounding_box->IsEmpty()) {
    return GeometryResult{
        .type = PrimitiveType::kTriangle,
        .vertex_buffer =
            VertexBuffer{
                .vertex_buffer = {},
                .vertex_count = 0,
                .index_type = IndexType::k16bit,
            },
        .transform = pass.GetOrthographicTransform() * entity.GetTransform(),
    };
  }

  VertexBuffer vertex_buffer;

  auto points = renderer.GetTessellator()->TessellateConvex(
      path_, entity.GetTransform().GetMaxBasisLength());

  vertex_buffer.vertex_buffer = host_buffer.Emplace(
      points.data(), points.size() * sizeof(Point), alignof(Point));
  vertex_buffer.index_buffer = {}, vertex_buffer.vertex_count = points.size();
  vertex_buffer.index_type = IndexType::kNone;

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = vertex_buffer,
      .transform = entity.GetShaderTransform(pass),
      .mode = GetResultMode(),
  };
}

// |Geometry|
GeometryResult FillPathGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  using VS = TextureFillVertexShader;

  const auto& bounding_box = path_.GetBoundingBox();
  if (bounding_box.has_value() && bounding_box->IsEmpty()) {
    return GeometryResult{
        .type = PrimitiveType::kTriangle,
        .vertex_buffer =
            VertexBuffer{
                .vertex_buffer = {},
                .vertex_count = 0,
                .index_type = IndexType::k16bit,
            },
        .transform = pass.GetOrthographicTransform() * entity.GetTransform(),
    };
  }

  auto uv_transform =
      texture_coverage.GetNormalizingTransform() * effect_transform;

  auto points = renderer.GetTessellator()->TessellateConvex(
      path_, entity.GetTransform().GetMaxBasisLength());

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.Reserve(points.size());
  for (auto i = 0u; i < points.size(); i++) {
    VS::PerVertexData data;
    data.position = points[i];
    data.texture_coords = uv_transform * points[i];
    vertex_builder.AppendVertex(data);
  }

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          vertex_builder.CreateVertexBuffer(renderer.GetTransientsBuffer()),
      .transform = entity.GetShaderTransform(pass),
      .mode = GetResultMode(),
  };
}

GeometryResult::Mode FillPathGeometry::GetResultMode() const {
  const auto& bounding_box = path_.GetBoundingBox();
  if (path_.IsConvex() ||
      (bounding_box.has_value() && bounding_box->IsEmpty())) {
    return GeometryResult::Mode::kNormal;
  }

  switch (path_.GetFillType()) {
    case FillType::kNonZero:
      return GeometryResult::Mode::kNonZero;
    case FillType::kOdd:
      return GeometryResult::Mode::kEvenOdd;
  }

  FML_UNREACHABLE();
}

GeometryVertexType FillPathGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> FillPathGeometry::GetCoverage(
    const Matrix& transform) const {
  return path_.GetTransformedBoundingBox(transform);
}

bool FillPathGeometry::CoversArea(const Matrix& transform,
                                  const Rect& rect) const {
  if (!inner_rect_.has_value()) {
    return false;
  }
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  Rect coverage = inner_rect_->TransformBounds(transform);
  return coverage.Contains(rect);
}

}  // namespace impeller
