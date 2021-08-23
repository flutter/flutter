// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents.h"

#include "flutter/fml/logging.h"
#include "impeller/compositor/render_pass.h"
#include "impeller/compositor/surface.h"
#include "impeller/compositor/tessellator.h"
#include "impeller/compositor/vertex_buffer_builder.h"
#include "impeller/entity/content_renderer.h"
#include "impeller/entity/entity.h"

namespace impeller {

Contents::Contents() = default;

Contents::~Contents() = default;

LinearGradientContents::LinearGradientContents() = default;

LinearGradientContents::~LinearGradientContents() = default;

void LinearGradientContents::SetEndPoints(Point start_point, Point end_point) {
  start_point_ = start_point;
  end_point_ = end_point;
}

void LinearGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
  if (colors_.empty()) {
    colors_.push_back(Color::Black());
    colors_.push_back(Color::Black());
  } else if (colors_.size() < 2u) {
    colors_.push_back(colors_.back());
  }
}

const std::vector<Color>& LinearGradientContents::GetColors() const {
  return colors_;
}

// |Contents|
bool LinearGradientContents::Render(const ContentRenderer& renderer,
                                    const Entity& entity,
                                    const Surface& surface,
                                    RenderPass& pass) const {
  using VS = GradientFillPipeline::VertexShader;
  using FS = GradientFillPipeline::FragmentShader;

  auto vertices_builder = VertexBufferBuilder<VS::PerVertexData>();
  {
    auto result =
        Tessellator{}.Tessellate(entity.GetPath().SubdivideAdaptively(),
                                 [&vertices_builder](Point point) {
                                   VS::PerVertexData vtx;
                                   vtx.vertices = point;
                                   vertices_builder.AppendVertex(vtx);
                                 });
    if (!result) {
      return false;
    }
  }

  VS::FrameInfo frame_info;
  frame_info.mvp =
      Matrix::MakeOrthographic(surface.GetSize()) * entity.GetTransformation();

  FS::GradientInfo gradient_info;
  gradient_info.start_point = start_point_;
  gradient_info.end_point = end_point_;
  gradient_info.start_color = colors_[0];
  gradient_info.end_color = colors_[1];

  Command cmd;
  cmd.label = "LinearGradientFill";
  cmd.pipeline = renderer.GetGradientFillPipeline();
  cmd.BindVertices(vertices_builder.CreateVertexBuffer(
      *renderer.GetContext()->GetPermanentsAllocator()));
  cmd.primitive_type = PrimitiveType::kTriangle;
  FS::BindGradientInfo(
      cmd, pass.GetTransientsBuffer().EmplaceUniform(gradient_info));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  return pass.RecordCommand(std::move(cmd));
}

}  // namespace impeller
