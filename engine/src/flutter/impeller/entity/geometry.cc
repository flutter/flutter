// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/renderer/device_buffer.h"

namespace impeller {

Geometry::Geometry() = default;

Geometry::~Geometry() = default;

// static
std::unique_ptr<Geometry> Geometry::MakeVertices(Vertices vertices) {
  return std::make_unique<VerticesGeometry>(std::move(vertices));
}

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
    HostBuffer& host_buffer) {
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

}  // namespace impeller
