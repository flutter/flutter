// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_vertices_geometry.h"

#include "impeller/core/device_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/render_pass.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"

namespace impeller {

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

// Fan mode isn't natively supported. Unroll into triangle mode by
// manipulating the index array.
//
// In Triangle fan, the first vertex is shared across all triangles, and then
// each sliding window of two vertices plus that first vertex defines a
// triangle.
static std::vector<uint16_t> fromFanIndices(
    const flutter::DlVertices* vertices) {
  FML_DCHECK(vertices->vertex_count() >= 3);
  FML_DCHECK(vertices->mode() == flutter::DlVertexMode::kTriangleFan);

  std::vector<uint16_t> indices;

  // Un-fan index buffer if provided.
  if (vertices->index_count() > 0) {
    auto* dl_indices = vertices->indices();
    auto center_point = dl_indices[0];
    for (int i = 1; i < vertices->index_count() - 1; i++) {
      indices.push_back(center_point);
      indices.push_back(dl_indices[i]);
      indices.push_back(dl_indices[i + 1]);
    }
  } else {
    // If indices were not provided, create an index buffer that unfans
    // triangles instead of re-writing points, colors, et cetera.
    for (int i = 1; i < vertices->vertex_count() - 1; i++) {
      indices.push_back(0);
      indices.push_back(i);
      indices.push_back(i + 1);
    }
  }
  return indices;
}

/////// Vertices Geometry ///////

// static
std::shared_ptr<VerticesGeometry> DlVerticesGeometry::MakeVertices(
    const flutter::DlVertices* vertices) {
  return std::make_shared<DlVerticesGeometry>(vertices);
}

DlVerticesGeometry::DlVerticesGeometry(const flutter::DlVertices* vertices)
    : vertices_(vertices) {
  NormalizeIndices();
}

DlVerticesGeometry::~DlVerticesGeometry() = default;

void DlVerticesGeometry::NormalizeIndices() {
  // Convert triangle fan if present.
  if (vertices_->mode() == flutter::DlVertexMode::kTriangleFan) {
    normalized_indices_ = fromFanIndices(vertices_);
    return;
  }

  auto index_count = vertices_->index_count();
  auto vertex_count = vertices_->vertex_count();
  if (index_count != 0 || vertex_count == 0) {
    return;
  }
  normalized_indices_.reserve(vertex_count);
  for (auto i = 0; i < vertex_count; i++) {
    normalized_indices_.push_back(i);
  }
}

static PrimitiveType GetPrimitiveType(const flutter::DlVertices* vertices) {
  switch (vertices->mode()) {
    case flutter::DlVertexMode::kTriangles:
      return PrimitiveType::kTriangle;
    case flutter::DlVertexMode::kTriangleStrip:
      return PrimitiveType::kTriangleStrip;
    case flutter::DlVertexMode::kTriangleFan:
      // Unrolled into triangle mode.
      return PrimitiveType::kTriangle;
  }
}

std::optional<Rect> DlVerticesGeometry::GetTextureCoordinateCoverge() const {
  if (!HasTextureCoordinates()) {
    return std::nullopt;
  }
  auto vertex_count = vertices_->vertex_count();
  auto* dl_texture_coordinates = vertices_->texture_coordinates();
  if (vertex_count == 0) {
    return std::nullopt;
  }

  auto left = dl_texture_coordinates[0].x();
  auto top = dl_texture_coordinates[0].y();
  auto right = dl_texture_coordinates[0].x();
  auto bottom = dl_texture_coordinates[0].y();

  for (auto i = 0; i < vertex_count; i++) {
    left = std::min(left, dl_texture_coordinates[i].x());
    top = std::min(top, dl_texture_coordinates[i].y());
    right = std::max(right, dl_texture_coordinates[i].x());
    bottom = std::max(bottom, dl_texture_coordinates[i].y());
  }
  return Rect::MakeLTRB(left, top, right, bottom);
}

bool DlVerticesGeometry::HasVertexColors() const {
  return vertices_->colors() != nullptr;
}

bool DlVerticesGeometry::HasTextureCoordinates() const {
  return vertices_->texture_coordinates() != nullptr;
}

GeometryResult DlVerticesGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  auto index_count = normalized_indices_.size() == 0
                         ? vertices_->index_count()
                         : normalized_indices_.size();
  auto vertex_count = vertices_->vertex_count();
  auto* dl_indices = normalized_indices_.size() == 0
                         ? vertices_->indices()
                         : normalized_indices_.data();
  auto* dl_vertices = vertices_->vertices();

  size_t total_vtx_bytes = vertex_count * sizeof(float) * 2;
  size_t total_idx_bytes = index_count * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer =
      renderer.GetContext()->GetResourceAllocator()->CreateBuffer(buffer_desc);

  if (!buffer->CopyHostBuffer(reinterpret_cast<const uint8_t*>(dl_vertices),
                              Range{0, total_vtx_bytes}, 0)) {
    return {};
  }
  if (!buffer->CopyHostBuffer(
          reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(dl_indices)),
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
              .vertex_count = index_count,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryResult DlVerticesGeometry::GetPositionColorBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  using VS = GeometryColorPipeline::VertexShader;

  auto index_count = normalized_indices_.size() == 0
                         ? vertices_->index_count()
                         : normalized_indices_.size();
  auto vertex_count = vertices_->vertex_count();
  auto* dl_indices = normalized_indices_.size() == 0
                         ? vertices_->indices()
                         : normalized_indices_.data();
  auto* dl_vertices = vertices_->vertices();
  auto* dl_colors = vertices_->colors();

  std::vector<VS::PerVertexData> vertex_data(vertex_count);
  {
    for (auto i = 0; i < vertex_count; i++) {
      auto dl_color = dl_colors[i];
      auto color = Color(dl_color.getRedF(), dl_color.getGreenF(),
                         dl_color.getBlueF(), dl_color.getAlphaF())
                       .Premultiply();
      auto sk_point = dl_vertices[i];
      vertex_data[i] = {
          .position = Point(sk_point.x(), sk_point.y()),
          .color = color,
      };
    }
  }

  size_t total_vtx_bytes = vertex_data.size() * sizeof(VS::PerVertexData);
  size_t total_idx_bytes = index_count * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer =
      renderer.GetContext()->GetResourceAllocator()->CreateBuffer(buffer_desc);

  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(vertex_data.data()),
                              Range{0, total_vtx_bytes}, 0)) {
    return {};
  }
  if (!buffer->CopyHostBuffer(
          reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(dl_indices)),
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
              .vertex_count = index_count,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryResult DlVerticesGeometry::GetPositionUVBuffer(
    Rect texture_coverage,
    Matrix effect_transform,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) {
  using VS = TexturePipeline::VertexShader;

  auto index_count = normalized_indices_.size() == 0
                         ? vertices_->index_count()
                         : normalized_indices_.size();
  auto vertex_count = vertices_->vertex_count();
  auto* dl_indices = normalized_indices_.size() == 0
                         ? vertices_->indices()
                         : normalized_indices_.data();
  auto* dl_vertices = vertices_->vertices();
  auto* dl_texture_coordinates = vertices_->texture_coordinates();

  auto size = texture_coverage.size;
  auto origin = texture_coverage.origin;
  std::vector<VS::PerVertexData> vertex_data(vertex_count);
  {
    for (auto i = 0; i < vertex_count; i++) {
      auto sk_point = dl_vertices[i];
      auto texture_coord = dl_texture_coordinates[i];
      auto uv = effect_transform *
                Point((texture_coord.x() - origin.x) / size.width,
                      (texture_coord.y() - origin.y) / size.height);
      // From experimentation we need to clamp these values to < 1.0 or else
      // there can be flickering.
      vertex_data[i] = {
          .position = Point(sk_point.x(), sk_point.y()),
          .texture_coords =
              Point(std::clamp(uv.x, 0.0f, 1.0f - kEhCloseEnough),
                    std::clamp(uv.y, 0.0f, 1.0f - kEhCloseEnough)),
      };
    }
  }

  size_t total_vtx_bytes = vertex_data.size() * sizeof(VS::PerVertexData);
  size_t total_idx_bytes = index_count * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer =
      renderer.GetContext()->GetResourceAllocator()->CreateBuffer(buffer_desc);

  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(vertex_data.data()),
                              Range{0, total_vtx_bytes}, 0)) {
    return {};
  }
  if (!buffer->CopyHostBuffer(
          reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(dl_indices)),
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
              .vertex_count = index_count,
              .index_type = IndexType::k16bit,
          },
      .transform = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation(),
      .prevent_overdraw = false,
  };
}

GeometryVertexType DlVerticesGeometry::GetVertexType() const {
  auto* dl_colors = vertices_->colors();
  if (dl_colors != nullptr) {
    return GeometryVertexType::kColor;
  }
  auto* dl_texture_coordinates = vertices_->texture_coordinates();
  if (dl_texture_coordinates != nullptr) {
    return GeometryVertexType::kUV;
  }

  return GeometryVertexType::kPosition;
}

std::optional<Rect> DlVerticesGeometry::GetCoverage(
    const Matrix& transform) const {
  return ToRect(vertices_->bounds()).TransformBounds(transform);
}

}  // namespace impeller
