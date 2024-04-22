// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/point_field_geometry.h"

#include "impeller/geometry/color.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

PointFieldGeometry::PointFieldGeometry(std::vector<Point> points,
                                       Scalar radius,
                                       bool round)
    : points_(std::move(points)), radius_(radius), round_(round) {}

GeometryResult PointFieldGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsCompute()) {
    return GetPositionBufferGPU(renderer, entity, pass);
  }
  auto vtx_builder = GetPositionBufferCPU(renderer, entity, pass);
  if (!vtx_builder.has_value()) {
    return {};
  }

  auto& host_buffer = renderer.GetTransientsBuffer();
  return {
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = vtx_builder->CreateVertexBuffer(host_buffer),
      .transform = entity.GetShaderTransform(pass),
  };
}

GeometryResult PointFieldGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsCompute()) {
    return GetPositionBufferGPU(renderer, entity, pass, texture_coverage,
                                effect_transform);
  }

  auto vtx_builder = GetPositionBufferCPU(renderer, entity, pass);
  if (!vtx_builder.has_value()) {
    return {};
  }
  auto uv_vtx_builder =
      ComputeUVGeometryCPU(vtx_builder.value(), {0, 0},
                           texture_coverage.GetSize(), effect_transform);

  auto& host_buffer = renderer.GetTransientsBuffer();
  return {
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = uv_vtx_builder.CreateVertexBuffer(host_buffer),
      .transform = entity.GetShaderTransform(pass),
  };
}

std::optional<VertexBufferBuilder<SolidFillVertexShader::PerVertexData>>
PointFieldGeometry::GetPositionBufferCPU(const ContentContext& renderer,
                                         const Entity& entity,
                                         RenderPass& pass) const {
  if (radius_ < 0.0) {
    return std::nullopt;
  }
  auto transform = entity.GetTransform();
  auto determinant = transform.GetDeterminant();
  if (determinant == 0) {
    return std::nullopt;
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar radius = std::max(radius_, min_size);

  VertexBufferBuilder<SolidFillVertexShader::PerVertexData> vtx_builder;

  if (round_) {
    // Get triangulation relative to {0, 0} so we can translate it to each
    // point in turn.
    auto generator =
        renderer.GetTessellator()->FilledCircle(transform, {}, radius);
    FML_DCHECK(generator.GetTriangleType() == PrimitiveType::kTriangleStrip);
    std::vector<Point> circle_vertices;
    circle_vertices.reserve(generator.GetVertexCount());
    generator.GenerateVertices([&circle_vertices](const Point& p) {  //
      circle_vertices.push_back(p);
    });
    FML_DCHECK(circle_vertices.size() == generator.GetVertexCount());

    vtx_builder.Reserve((circle_vertices.size() + 2) * points_.size() - 2);
    for (auto& center : points_) {
      if (vtx_builder.HasVertices()) {
        vtx_builder.AppendVertex(vtx_builder.Last());
        vtx_builder.AppendVertex({center + circle_vertices[0]});
      }

      for (auto& vertex : circle_vertices) {
        vtx_builder.AppendVertex({center + vertex});
      }
    }
  } else {
    vtx_builder.Reserve(6 * points_.size() - 2);
    for (auto& point : points_) {
      auto first = Point(point.x - radius, point.y - radius);

      if (vtx_builder.HasVertices()) {
        vtx_builder.AppendVertex(vtx_builder.Last());
        vtx_builder.AppendVertex({first});
      }

      // Z pattern from UL -> UR -> LL -> LR
      vtx_builder.AppendVertex({first});
      vtx_builder.AppendVertex({{point.x + radius, point.y - radius}});
      vtx_builder.AppendVertex({{point.x - radius, point.y + radius}});
      vtx_builder.AppendVertex({{point.x + radius, point.y + radius}});
    }
  }

  return vtx_builder;
}

GeometryResult PointFieldGeometry::GetPositionBufferGPU(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    std::optional<Rect> texture_coverage,
    std::optional<Matrix> effect_transform) const {
  FML_DCHECK(renderer.GetDeviceCapabilities().SupportsCompute());
  if (radius_ < 0.0) {
    return {};
  }
  Scalar determinant = entity.GetTransform().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar radius = std::max(radius_, min_size);

  size_t vertices_per_geom = ComputeCircleDivisions(
      entity.GetTransform().GetMaxBasisLength() * radius, round_);

  size_t points_per_circle = 3 + (vertices_per_geom - 3) * 3;
  size_t total = points_per_circle * points_.size();

  std::shared_ptr<CommandBuffer> cmd_buffer =
      renderer.GetContext()->CreateCommandBuffer();
  std::shared_ptr<ComputePass> compute_pass = cmd_buffer->CreateComputePass();
  HostBuffer& host_buffer = renderer.GetTransientsBuffer();

  BufferView points_data =
      host_buffer.Emplace(points_.data(), points_.size() * sizeof(Point),
                          DefaultUniformAlignment());

  BufferView geometry_buffer =
      host_buffer.Emplace(nullptr, total * sizeof(Point),
                          std::max(DefaultUniformAlignment(), alignof(Point)));

  BufferView output;
  {
    using PS = PointsComputeShader;

    compute_pass->SetPipeline(renderer.GetPointComputePipeline());
    compute_pass->SetCommandLabel("Points Geometry");

    PS::FrameInfo frame_info;
    frame_info.count = points_.size();
    frame_info.radius = round_ ? radius : radius * kSqrt2;
    frame_info.radian_start = round_ ? 0.0f : kPiOver4;
    frame_info.radian_step = k2Pi / vertices_per_geom;
    frame_info.points_per_circle = points_per_circle;
    frame_info.divisions_per_circle = vertices_per_geom;

    PS::BindFrameInfo(*compute_pass, host_buffer.EmplaceUniform(frame_info));
    PS::BindGeometryData(*compute_pass, geometry_buffer);
    PS::BindPointData(*compute_pass, points_data);

    if (!compute_pass->Compute(ISize(total, 1)).ok()) {
      return {};
    }
    output = geometry_buffer;
  }

  if (texture_coverage.has_value() && effect_transform.has_value()) {
    BufferView geometry_uv_buffer = host_buffer.Emplace(
        nullptr, total * sizeof(Vector4),
        std::max(DefaultUniformAlignment(), alignof(Vector4)));

    using UV = UvComputeShader;

    compute_pass->AddBufferMemoryBarrier();
    compute_pass->SetCommandLabel("UV Geometry");
    compute_pass->SetPipeline(renderer.GetUvComputePipeline());

    UV::FrameInfo frame_info;
    frame_info.count = total;
    frame_info.effect_transform = effect_transform.value();
    frame_info.texture_origin = {0, 0};
    frame_info.texture_size = Vector2(texture_coverage.value().GetSize());

    UV::BindFrameInfo(*compute_pass, host_buffer.EmplaceUniform(frame_info));
    UV::BindGeometryData(*compute_pass, geometry_buffer);
    UV::BindGeometryUVData(*compute_pass, geometry_uv_buffer);

    if (!compute_pass->Compute(ISize(total, 1)).ok()) {
      return {};
    }
    output = geometry_uv_buffer;
  }

  if (!compute_pass->EncodeCommands()) {
    return {};
  }
  if (!renderer.GetContext()
           ->GetCommandQueue()
           ->Submit({std::move(cmd_buffer)})
           .ok()) {
    return {};
  }

  return {
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = {.vertex_buffer = std::move(output),
                        .vertex_count = total,
                        .index_type = IndexType::kNone},
      .transform = entity.GetShaderTransform(pass),
  };
}

/// @brief Compute the number of vertices to divide each circle into.
///
/// @return the number of vertices.
size_t PointFieldGeometry::ComputeCircleDivisions(Scalar scaled_radius,
                                                  bool round) {
  if (!round) {
    return 4;
  }

  // Note: these values are approximated based on the values returned from
  // the decomposition of 4 cubics performed by Path::CreatePolyline.
  if (scaled_radius < 1.0) {
    return 4;
  }
  if (scaled_radius < 2.0) {
    return 8;
  }
  if (scaled_radius < 12.0) {
    return 24;
  }
  if (scaled_radius < 22.0) {
    return 34;
  }
  return std::min(scaled_radius, 140.0f);
}

// |Geometry|
GeometryVertexType PointFieldGeometry::GetVertexType() const {
  return GeometryVertexType::kPosition;
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
