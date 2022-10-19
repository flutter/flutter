// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/device_buffer.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

Geometry::Geometry() = default;

Geometry::~Geometry() = default;

// static
std::unique_ptr<Geometry> Geometry::MakeVertices(Vertices vertices) {
  return std::make_unique<VerticesGeometry>(std::move(vertices));
}

std::unique_ptr<Geometry> Geometry::MakePath(Path path) {
  return std::make_unique<PathGeometry>(std::move(path));
}

std::unique_ptr<Geometry> Geometry::MakeCover() {
  return std::make_unique<CoverGeometry>();
}

/////// Vertices Geometry ///////

VerticesGeometry::VerticesGeometry(Vertices vertices)
    : vertices_(std::move(vertices)) {}

VerticesGeometry::~VerticesGeometry() = default;

static PrimitiveType GetPrimitiveType(const Vertices& vertices) {
  switch (vertices.GetMode()) {
    case VertexMode::kTriangle:
      return PrimitiveType::kTriangle;
    case VertexMode::kTriangleStrip:
      return PrimitiveType::kTriangleStrip;
  }
}

GeometryResult VerticesGeometry::GetPositionBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  if (!vertices_.IsValid()) {
    return {};
  }

  auto vertex_count = vertices_.GetPositions().size();
  size_t total_vtx_bytes = vertex_count * sizeof(float) * 2;
  size_t total_idx_bytes = vertices_.GetIndices().size() * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer = device_allocator->CreateBuffer(buffer_desc);

  const auto& positions = vertices_.GetPositions();
  if (!buffer->CopyHostBuffer(
          reinterpret_cast<const uint8_t*>(positions.data()),
          Range{0, total_vtx_bytes}, 0)) {
    return {};
  }
  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(
                                  vertices_.GetIndices().data())),
                              Range{0, total_idx_bytes}, total_vtx_bytes)) {
    return {};
  }

  return GeometryResult{
      .type = GetPrimitiveType(vertices_),
      .vertex_buffer =
          {
              .vertex_buffer = {.buffer = buffer,
                                .range = Range{0, total_vtx_bytes}},
              .index_buffer = {.buffer = buffer,
                               .range =
                                   Range{total_vtx_bytes, total_idx_bytes}},
              .index_count = vertices_.GetIndices().size(),
              .index_type = IndexType::k16bit,
          },
      .prevent_overdraw = false,
  };
}

GeometryResult VerticesGeometry::GetPositionColorBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    Color paint_color,
    BlendMode blend_mode) {
  using VS = GeometryColorPipeline::VertexShader;

  if (!vertices_.IsValid()) {
    return {};
  }

  auto vertex_count = vertices_.GetPositions().size();
  std::vector<VS::PerVertexData> vertex_data(vertex_count);
  {
    const auto& positions = vertices_.GetPositions();
    const auto& colors = vertices_.GetColors();
    for (size_t i = 0; i < vertex_count; i++) {
      auto color = Color::BlendColor(paint_color, colors[i], blend_mode);
      vertex_data[i] = {
          .position = positions[i],
          .color = color,
      };
    }
  }

  size_t total_vtx_bytes = vertex_data.size() * sizeof(VS::PerVertexData);
  size_t total_idx_bytes = vertices_.GetIndices().size() * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer = device_allocator->CreateBuffer(buffer_desc);

  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(vertex_data.data()),
                              Range{0, total_vtx_bytes}, 0)) {
    return {};
  }
  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(
                                  vertices_.GetIndices().data())),
                              Range{0, total_idx_bytes}, total_vtx_bytes)) {
    return {};
  }

  return GeometryResult{
      .type = GetPrimitiveType(vertices_),
      .vertex_buffer =
          {
              .vertex_buffer = {.buffer = buffer,
                                .range = Range{0, total_vtx_bytes}},
              .index_buffer = {.buffer = buffer,
                               .range =
                                   Range{total_vtx_bytes, total_idx_bytes}},
              .index_count = vertices_.GetIndices().size(),
              .index_type = IndexType::k16bit,
          },
      .prevent_overdraw = false,
  };
}

GeometryResult VerticesGeometry::GetPositionUVBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  // TODO(jonahwilliams): support texture coordinates in vertices.
  return {};
}

GeometryVertexType VerticesGeometry::GetVertexType() {
  if (vertices_.GetColors().size()) {
    return GeometryVertexType::kColor;
  }
  return GeometryVertexType::kPosition;
}

std::optional<Rect> VerticesGeometry::GetCoverage(Matrix transform) {
  return vertices_.GetTransformedBoundingBox(transform);
}

/////// Path Geometry ///////

PathGeometry::PathGeometry(Path path) : path_(std::move(path)) {}

PathGeometry::~PathGeometry() = default;

GeometryResult PathGeometry::GetPositionBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  VertexBuffer vertex_buffer;
  auto tesselation_result = tessellator->Tessellate(
      path_.GetFillType(), path_.CreatePolyline(),
      [&vertex_buffer, &host_buffer](
          const float* vertices, size_t vertices_count, const uint16_t* indices,
          size_t indices_count) {
        vertex_buffer.vertex_buffer = host_buffer.Emplace(
            vertices, vertices_count * sizeof(float), alignof(float));
        vertex_buffer.index_buffer = host_buffer.Emplace(
            indices, indices_count * sizeof(uint16_t), alignof(uint16_t));
        vertex_buffer.index_count = indices_count;
        vertex_buffer.index_type = IndexType::k16bit;
        return true;
      });
  if (tesselation_result != Tessellator::Result::kSuccess) {
    return {};
  }
  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer = vertex_buffer,
      .prevent_overdraw = false,
  };
}

GeometryResult PathGeometry::GetPositionColorBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    Color paint_color,
    BlendMode blend_mode) {
  // TODO(jonahwilliams): support per-color vertex in path geometry.
  return {};
}

GeometryResult PathGeometry::GetPositionUVBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  // TODO(jonahwilliams): support texture coordinates in path geometry.
  return {};
}

GeometryVertexType PathGeometry::GetVertexType() {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> PathGeometry::GetCoverage(Matrix transform) {
  return path_.GetTransformedBoundingBox(transform);
}

/////// Cover Geometry ///////

CoverGeometry::CoverGeometry() = default;

CoverGeometry::~CoverGeometry() = default;

GeometryResult CoverGeometry::GetPositionBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  auto rect = Rect(Size(render_target_size));
  constexpr uint16_t kRectIndicies[4] = {0, 1, 2, 3};
  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer = {.vertex_buffer = host_buffer.Emplace(
                            rect.GetPoints().data(), 8 * sizeof(float),
                            alignof(float)),
                        .index_buffer = host_buffer.Emplace(
                            kRectIndicies, 4 * sizeof(uint16_t),
                            alignof(uint16_t)),
                        .index_count = 4,
                        .index_type = IndexType::k16bit},
      .prevent_overdraw = false,
  };
}

GeometryResult CoverGeometry::GetPositionColorBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    Color paint_color,
    BlendMode blend_mode) {
  // TODO(jonahwilliams): support per-color vertex in cover geometry.
  return {};
}

GeometryResult CoverGeometry::GetPositionUVBuffer(
    std::shared_ptr<Allocator> device_allocator,
    HostBuffer& host_buffer,
    std::shared_ptr<Tessellator> tessellator,
    ISize render_target_size) {
  // TODO(jonahwilliams): support texture coordinates in cover geometry.
  return {};
}

GeometryVertexType CoverGeometry::GetVertexType() {
  return GeometryVertexType::kPosition;
}

std::optional<Rect> CoverGeometry::GetCoverage(Matrix transform) {
  return Rect::MakeMaximum();
}

}  // namespace impeller
