// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/entity/vertices.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

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

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  using VS = VerticesVertexShader;

  const auto coverage_rect = vertices_.GetBoundingBox();

  if (!coverage_rect.has_value()) {
    return true;
  }

  if (coverage_rect->size.IsEmpty()) {
    return true;
  }

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  std::vector<Point> points = vertices_.GetPoints();
  std::vector<uint16_t> indices = vertices_.GetIndices();
  // TODO: colors are currently unused, must be blended with
  // paint color based on provided blend mode.
  std::vector<Color> colors = vertices_.GetColors();
  VertexMode mode = vertices_.GetMode();

  if (indices.size() == 0) {
    for (size_t i = 0; i < points.size(); i += 1) {
      VS::PerVertexData data;
      data.point = points[i];
      data.vertex_color = color_;
      vertex_builder.AppendVertex(data);
    }
  } else {
    for (size_t i = 0; i < indices.size(); i += 1) {
      VS::PerVertexData data;
      data.point = points[indices[i]];
      data.vertex_color = color_;
      vertex_builder.AppendVertex(data);
    }
  }

  PrimitiveType primitiveType;
  switch (mode) {
    case VertexMode::kTriangle:
      primitiveType = PrimitiveType::kTriangle;
      break;
    case VertexMode::kTriangleStrip:
      primitiveType = PrimitiveType::kTriangleStrip;
      break;
  }

  if (!vertex_builder.HasVertices()) {
    return true;
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
  cmd.primitive_type = primitiveType;
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
  pass.AddCommand(std::move(cmd));

  return true;
}

}  // namespace impeller
