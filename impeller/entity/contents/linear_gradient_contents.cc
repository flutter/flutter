// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "linear_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

LinearGradientContents::LinearGradientContents() = default;

LinearGradientContents::~LinearGradientContents() = default;

void LinearGradientContents::SetEndPoints(Point start_point, Point end_point) {
  start_point_ = start_point;
  end_point_ = end_point;
}

void LinearGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
}

void LinearGradientContents::SetStops(std::vector<Scalar> stops) {
  stops_ = std::move(stops);
}

const std::vector<Color>& LinearGradientContents::GetColors() const {
  return colors_;
}

const std::vector<Scalar>& LinearGradientContents::GetStops() const {
  return stops_;
}

void LinearGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

bool LinearGradientContents::Render(const ContentContext& renderer,
                                    const Entity& entity,
                                    RenderPass& pass) const {
  using VS = LinearGradientFillPipeline::VertexShader;
  using FS = LinearGradientFillPipeline::FragmentShader;

  auto vertices_builder = VertexBufferBuilder<VS::PerVertexData>();
  {
    auto result = Tessellator{}.Tessellate(GetPath().GetFillType(),
                                           GetPath().CreatePolyline(),
                                           [&vertices_builder](Point point) {
                                             VS::PerVertexData vtx;
                                             vtx.position = point;
                                             vertices_builder.AppendVertex(vtx);
                                           });

    if (result == Tessellator::Result::kInputError) {
      return true;
    }
    if (result == Tessellator::Result::kTessellationError) {
      return false;
    }
  }

  auto gradient_texture =
      CreateGradientTexture(colors_, stops_, renderer.GetContext());
  if (gradient_texture == nullptr) {
    return false;
  }

  FS::GradientInfo gradient_info;
  gradient_info.start_point = start_point_;
  gradient_info.end_point = end_point_;
  gradient_info.tile_mode = static_cast<Scalar>(tile_mode_);
  gradient_info.texture_sampler_y_coord_scale =
      gradient_texture->GetYCoordScale();

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.matrix = GetInverseMatrix();

  Command cmd;
  cmd.label = "LinearGradientFill";
  cmd.pipeline = renderer.GetLinearGradientFillPipeline(
      OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(
      vertices_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));
  cmd.primitive_type = PrimitiveType::kTriangle;
  FS::BindGradientInfo(
      cmd, pass.GetTransientsBuffer().EmplaceUniform(gradient_info));
  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;
  FS::BindTextureSampler(
      cmd, std::move(gradient_texture),
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
