// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/entity/vertices.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

VerticesContents::VerticesContents(Vertices vertices)
    : vertices_(std::move(vertices)){};

VerticesContents::~VerticesContents() = default;

std::optional<Rect> VerticesContents::GetCoverage(const Entity& entity) const {
  return vertices_.GetTransformedBoundingBox(entity.GetTransformation());
};

void VerticesContents::SetColor(Color color) {
  color_ = color.Premultiply();
}

void VerticesContents::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

static PrimitiveType GetPrimitiveType(const Vertices& vertices) {
  switch (vertices.GetMode()) {
    case VertexMode::kTriangle:
      return PrimitiveType::kTriangle;
    case VertexMode::kTriangleStrip:
      return PrimitiveType::kTriangleStrip;
  }
}

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  if (!vertices_.IsValid()) {
    return true;
  }

  using VS = VerticesPipeline::VertexShader;

  const auto coverage_rect = vertices_.GetBoundingBox();

  if (!coverage_rect.has_value()) {
    return true;
  }

  if (coverage_rect->size.IsEmpty()) {
    return true;
  }

  std::vector<VS::PerVertexData> vertex_data;
  {
    const auto& positions = vertices_.GetPositions();
    const auto& colors = vertices_.GetColors();
    for (size_t i = 0; i < positions.size(); i++) {
      auto color = i < colors.size()
                       ? Color::BlendColor(color_, colors[i], blend_mode_)
                       : color_;
      vertex_data.push_back(VS::PerVertexData{
          .position = positions[i],
          .color = color,
      });
    }
  }

  size_t total_vtx_bytes = vertex_data.size() * sizeof(VS::PerVertexData);
  size_t total_idx_bytes = vertices_.GetIndices().size() * sizeof(uint16_t);

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = total_vtx_bytes + total_idx_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;

  auto buffer =
      renderer.GetContext()->GetResourceAllocator()->CreateBuffer(buffer_desc);

  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(vertex_data.data()),
                              Range{0, total_vtx_bytes}, 0)) {
    return false;
  }
  if (!buffer->CopyHostBuffer(reinterpret_cast<uint8_t*>(const_cast<uint16_t*>(
                                  vertices_.GetIndices().data())),
                              Range{0, total_idx_bytes}, total_vtx_bytes)) {
    return false;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  Command cmd;
  cmd.label = "Vertices";
  cmd.pipeline =
      renderer.GetVerticesPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.primitive_type = GetPrimitiveType(vertices_);
  cmd.BindVertices({
      .vertex_buffer = {.buffer = buffer, .range = Range{0, total_vtx_bytes}},
      .index_buffer = {.buffer = buffer,
                       .range = Range{total_vtx_bytes, total_idx_bytes}},
      .index_count = vertices_.GetIndices().size(),
      .index_type = IndexType::k16bit,
  });
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
  pass.AddCommand(std::move(cmd));

  return true;
}

}  // namespace impeller
