// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/fill_path_geometry.h"

namespace impeller {

FillPathGeometry::FillPathGeometry(const Path& path) : path_(path) {}

FillPathGeometry::~FillPathGeometry() = default;

GeometryResult FillPathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  auto& host_buffer = pass.GetTransientsBuffer();
  VertexBuffer vertex_buffer;

  if (path_.GetFillType() == FillType::kNonZero &&  //
      path_.IsConvex()) {
    auto [points, indices] = TessellateConvex(
        path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()));

    vertex_buffer.vertex_buffer = host_buffer.Emplace(
        points.data(), points.size() * sizeof(Point), alignof(Point));
    vertex_buffer.index_buffer = host_buffer.Emplace(
        indices.data(), indices.size() * sizeof(uint16_t), alignof(uint16_t));
    vertex_buffer.vertex_count = indices.size();
    vertex_buffer.index_type = IndexType::k16bit;

    return GeometryResult{
        .type = PrimitiveType::kTriangle,
        .vertex_buffer = vertex_buffer,
        .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     entity.GetTransformation(),
        .prevent_overdraw = false,
    };
  }

  auto tesselation_result = renderer.GetTessellator()->Tessellate(
      path_.GetFillType(),
      path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()),
      [&vertex_buffer, &host_buffer](
          const float* vertices, size_t vertices_count, const uint16_t* indices,
          size_t indices_count) {
        vertex_buffer.vertex_buffer = host_buffer.Emplace(
            vertices, vertices_count * sizeof(float), alignof(float));
        vertex_buffer.index_buffer = host_buffer.Emplace(
            indices, indices_count * sizeof(uint16_t), alignof(uint16_t));
        vertex_buffer.vertex_count = indices_count;
        vertex_buffer.index_type = IndexType::k16bit;
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = vertex_buffer,
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

// |Geometry|
GeometryResult FillPathGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  using VS = TextureFillVertexShader;

  if (path_.GetFillType() == FillType::kNonZero &&  //
      path_.IsConvex()) {
    auto [points, indices] = TessellateConvex(
        path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()));

    VertexBufferBuilder<VS::PerVertexData> vertex_builder;
    vertex_builder.Reserve(points.size());
    vertex_builder.ReserveIndices(indices.size());
    for (auto i = 0u; i < points.size(); i++) {
      VS::PerVertexData data;
      data.position = points[i];
      auto coverage_coords =
          (points[i] - texture_coverage.origin) / texture_coverage.size;
      data.texture_coords = effect_transform * coverage_coords;
      vertex_builder.AppendVertex(data);
    }
    for (auto i = 0u; i < indices.size(); i++) {
      vertex_builder.AppendIndex(indices[i]);
    }

    return GeometryResult{
        .type = PrimitiveType::kTriangle,
        .vertex_buffer =
            vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer()),
        .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     entity.GetTransformation(),
        .prevent_overdraw = false,
    };
  }

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  auto tesselation_result = renderer.GetTessellator()->Tessellate(
      path_.GetFillType(),
      path_.CreatePolyline(entity.GetTransformation().GetMaxBasisLength()),
      [&vertex_builder, &texture_coverage, &effect_transform](
          const float* vertices, size_t vertices_count, const uint16_t* indices,
          size_t indices_count) {
        for (auto i = 0u; i < vertices_count; i += 2) {
          VS::PerVertexData data;
          Point vtx = {vertices[i], vertices[i + 1]};
          data.position = vtx;
          auto coverage_coords =
              (vtx - texture_coverage.origin) / texture_coverage.size;
          data.texture_coords = effect_transform * coverage_coords;
          vertex_builder.AppendVertex(data);
        }
        FML_DCHECK(vertex_builder.GetVertexCount() == vertices_count / 2);
        for (auto i = 0u; i < indices_count; i++) {
          vertex_builder.AppendIndex(indices[i]);
        }
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer =
          vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer()),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryVertexType FillPathGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> FillPathGeometry::GetCoverage(
    const Matrix& transform) const {
  return path_.GetTransformedBoundingBox(transform);
}

}  // namespace impeller
