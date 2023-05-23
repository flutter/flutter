// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/point_field_geometry.h"

#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_command.h"

namespace impeller {

PointFieldGeometry::PointFieldGeometry(std::vector<Point> points,
                                       Scalar radius,
                                       bool round)
    : points_(std::move(points)), radius_(radius), round_(round) {}

PointFieldGeometry::~PointFieldGeometry() = default;

GeometryResult PointFieldGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  if (renderer.GetDeviceCapabilities().SupportsCompute()) {
    return GetPositionBufferGPU(renderer, entity, pass);
  }
  auto vtx_builder = GetPositionBufferCPU(renderer, entity, pass);
  if (!vtx_builder.has_value()) {
    return {};
  }

  auto& host_buffer = pass.GetTransientsBuffer();
  return {
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = vtx_builder->CreateVertexBuffer(host_buffer),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryResult PointFieldGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  if (renderer.GetDeviceCapabilities().SupportsCompute()) {
    return GetPositionBufferGPU(renderer, entity, pass, texture_coverage,
                                effect_transform);
  }

  auto vtx_builder = GetPositionBufferCPU(renderer, entity, pass);
  if (!vtx_builder.has_value()) {
    return {};
  }
  auto uv_vtx_builder = ComputeUVGeometryCPU(
      vtx_builder.value(), {0, 0}, texture_coverage.size, effect_transform);

  auto& host_buffer = pass.GetTransientsBuffer();
  return {
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = uv_vtx_builder.CreateVertexBuffer(host_buffer),
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

std::optional<VertexBufferBuilder<SolidFillVertexShader::PerVertexData>>
PointFieldGeometry::GetPositionBufferCPU(const ContentContext& renderer,
                                         const Entity& entity,
                                         RenderPass& pass) {
  if (radius_ < 0.0) {
    return std::nullopt;
  }
  auto determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return std::nullopt;
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar radius = std::max(radius_, min_size);

  auto vertices_per_geom = ComputeCircleDivisions(
      entity.GetTransformation().GetMaxBasisLength() * radius, round_);
  auto points_per_circle = 3 + (vertices_per_geom - 3) * 3;
  auto total = points_per_circle * points_.size();
  auto radian_start = round_ ? 0.0f : 0.785398f;
  auto radian_step = k2Pi / vertices_per_geom;

  VertexBufferBuilder<SolidFillVertexShader::PerVertexData> vtx_builder;
  vtx_builder.Reserve(total);

  /// Precompute all relative points and angles for a fixed geometry size.
  auto elapsed_angle = radian_start;
  std::vector<Point> angle_table(vertices_per_geom);
  for (auto i = 0u; i < vertices_per_geom; i++) {
    angle_table[i] = Point(cos(elapsed_angle), sin(elapsed_angle)) * radius;
    elapsed_angle += radian_step;
  }

  for (auto i = 0u; i < points_.size(); i++) {
    auto center = points_[i];

    auto origin = center + angle_table[0];
    vtx_builder.AppendVertex({origin});

    auto pt1 = center + angle_table[1];
    vtx_builder.AppendVertex({pt1});

    auto pt2 = center + angle_table[2];
    vtx_builder.AppendVertex({pt2});

    for (auto j = 0u; j < vertices_per_geom - 3; j++) {
      vtx_builder.AppendVertex({origin});
      vtx_builder.AppendVertex({pt2});

      pt2 = center + angle_table[j + 3];
      vtx_builder.AppendVertex({pt2});
    }
  }
  return vtx_builder;
}

GeometryResult PointFieldGeometry::GetPositionBufferGPU(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    std::optional<Rect> texture_coverage,
    std::optional<Matrix> effect_transform) {
  FML_DCHECK(renderer.GetDeviceCapabilities().SupportsCompute());
  if (radius_ < 0.0) {
    return {};
  }
  auto determinant = entity.GetTransformation().GetDeterminant();
  if (determinant == 0) {
    return {};
  }

  Scalar min_size = 1.0f / sqrt(std::abs(determinant));
  Scalar radius = std::max(radius_, min_size);

  auto vertices_per_geom = ComputeCircleDivisions(
      entity.GetTransformation().GetMaxBasisLength() * radius, round_);

  auto points_per_circle = 3 + (vertices_per_geom - 3) * 3;
  auto total = points_per_circle * points_.size();

  auto cmd_buffer = renderer.GetContext()->CreateCommandBuffer();
  auto compute_pass = cmd_buffer->CreateComputePass();
  auto& host_buffer = compute_pass->GetTransientsBuffer();

  auto points_data =
      host_buffer.Emplace(points_.data(), points_.size() * sizeof(Point),
                          DefaultUniformAlignment());

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total * sizeof(Point);
  buffer_desc.storage_mode = StorageMode::kDevicePrivate;

  auto geometry_buffer = renderer.GetContext()
                             ->GetResourceAllocator()
                             ->CreateBuffer(buffer_desc)
                             ->AsBufferView();

  BufferView output;
  {
    using PS = PointsComputeShader;
    ComputeCommand cmd;
    cmd.label = "Points Geometry";
    cmd.pipeline = renderer.GetPointComputePipeline();

    PS::FrameInfo frame_info;
    frame_info.count = points_.size();
    frame_info.radius = radius;
    frame_info.radian_start = round_ ? 0.0f : kPiOver4;
    frame_info.radian_step = k2Pi / vertices_per_geom;
    frame_info.points_per_circle = points_per_circle;
    frame_info.divisions_per_circle = vertices_per_geom;

    PS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
    PS::BindGeometryData(cmd, geometry_buffer);
    PS::BindPointData(cmd, points_data);

    if (!compute_pass->AddCommand(std::move(cmd))) {
      return {};
    }
    output = geometry_buffer;
  }

  if (texture_coverage.has_value() && effect_transform.has_value()) {
    DeviceBufferDescriptor buffer_desc;
    buffer_desc.size = total * sizeof(Vector4);
    buffer_desc.storage_mode = StorageMode::kDevicePrivate;

    auto geometry_uv_buffer = renderer.GetContext()
                                  ->GetResourceAllocator()
                                  ->CreateBuffer(buffer_desc)
                                  ->AsBufferView();

    using UV = UvComputeShader;

    ComputeCommand cmd;
    cmd.label = "UV Geometry";
    cmd.pipeline = renderer.GetUvComputePipeline();

    UV::FrameInfo frame_info;
    frame_info.count = total;
    frame_info.effect_transform = effect_transform.value();
    frame_info.texture_origin = {0, 0};
    frame_info.texture_size = Vector2(texture_coverage.value().size);

    UV::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
    UV::BindGeometryData(cmd, geometry_buffer);
    UV::BindGeometryUVData(cmd, geometry_uv_buffer);

    if (!compute_pass->AddCommand(std::move(cmd))) {
      return {};
    }
    output = geometry_uv_buffer;
  }

  compute_pass->SetGridSize(ISize(total, 1));
  compute_pass->SetThreadGroupSize(ISize(total, 1));

  if (!compute_pass->EncodeCommands() || !cmd_buffer->SubmitCommands()) {
    return {};
  }

  return {
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = {.vertex_buffer = output,
                        .vertex_count = total,
                        .index_type = IndexType::kNone},
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
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
    return Rect::MakeLTRB(left - radius_, top - radius_, right + radius_,
                          bottom + radius_);
  }
  return std::nullopt;
}

}  // namespace impeller
