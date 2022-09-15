// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "linear_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/contents/solid_fill_utils.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

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
  gradient_info.alpha = GetAlpha();
  gradient_info.half_texel = Vector2(0.5 / gradient_texture->GetSize().width,
                                     0.5 / gradient_texture->GetSize().height);

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.matrix = GetInverseMatrix();

  Command cmd;
  cmd.label = "LinearGradientFill";
  cmd.pipeline = renderer.GetLinearGradientFillPipeline(
      OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(CreateSolidFillVertices<VS::PerVertexData>(
      GetCover()
          ? PathBuilder{}.AddRect(Size(pass.GetRenderTargetSize())).TakePath()
          : GetPath(),
      pass.GetTransientsBuffer()));
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
