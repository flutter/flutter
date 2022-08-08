// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sweep_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

SweepGradientContents::SweepGradientContents() = default;

SweepGradientContents::~SweepGradientContents() = default;

void SweepGradientContents::SetPath(Path path) {
  path_ = std::move(path);
}

void SweepGradientContents::SetCenterAndAngles(Point center,
                                               Degrees start_angle,
                                               Degrees end_angle) {
  center_ = center;
  Scalar t0 = start_angle.degrees / 360;
  Scalar t1 = end_angle.degrees / 360;
  FML_DCHECK(t0 < t1);
  bias_ = -t0;
  scale_ = 1 / (t1 - t0);
}

void SweepGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
  if (colors_.empty()) {
    colors_.push_back(Color::Black());
    colors_.push_back(Color::Black());
  } else if (colors_.size() < 2u) {
    colors_.push_back(colors_.back());
  }
}

void SweepGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

const std::vector<Color>& SweepGradientContents::GetColors() const {
  return colors_;
}

std::optional<Rect> SweepGradientContents::GetCoverage(
    const Entity& entity) const {
  return path_.GetTransformedBoundingBox(entity.GetTransformation());
};

bool SweepGradientContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  using VS = SweepGradientFillPipeline::VertexShader;
  using FS = SweepGradientFillPipeline::FragmentShader;

  auto vertices_builder = VertexBufferBuilder<VS::PerVertexData>();
  {
    auto result =
        Tessellator{}.Tessellate(path_.GetFillType(), path_.CreatePolyline(),
                                 [&vertices_builder](Point point) {
                                   VS::PerVertexData vtx;
                                   vtx.vertices = point;
                                   vertices_builder.AppendVertex(vtx);
                                 });

    if (result == Tessellator::Result::kInputError) {
      return true;
    }
    if (result == Tessellator::Result::kTessellationError) {
      return false;
    }
  }

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();

  FS::GradientInfo gradient_info;
  gradient_info.center = center_;
  gradient_info.bias = bias_;
  gradient_info.scale = scale_;
  gradient_info.start_color = colors_[0].Premultiply();
  gradient_info.end_color = colors_[1].Premultiply();
  gradient_info.tile_mode = static_cast<Scalar>(tile_mode_);

  Command cmd;
  cmd.label = "SweepGradientFill";
  cmd.pipeline = renderer.GetSweepGradientFillPipeline(
      OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(
      vertices_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));
  cmd.primitive_type = PrimitiveType::kTriangle;
  FS::BindGradientInfo(
      cmd, pass.GetTransientsBuffer().EmplaceUniform(gradient_info));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
