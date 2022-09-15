// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sweep_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/contents/solid_fill_utils.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

SweepGradientContents::SweepGradientContents() = default;

SweepGradientContents::~SweepGradientContents() = default;

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
}

void SweepGradientContents::SetStops(std::vector<Scalar> stops) {
  stops_ = std::move(stops);
}

void SweepGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

const std::vector<Color>& SweepGradientContents::GetColors() const {
  return colors_;
}

const std::vector<Scalar>& SweepGradientContents::GetStops() const {
  return stops_;
}

bool SweepGradientContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  using VS = SweepGradientFillPipeline::VertexShader;
  using FS = SweepGradientFillPipeline::FragmentShader;

  auto gradient_texture =
      CreateGradientTexture(colors_, stops_, renderer.GetContext());
  if (gradient_texture == nullptr) {
    return false;
  }

  FS::GradientInfo gradient_info;
  gradient_info.center = center_;
  gradient_info.bias = bias_;
  gradient_info.scale = scale_;
  gradient_info.texture_sampler_y_coord_scale =
      gradient_texture->GetYCoordScale();
  gradient_info.tile_mode = static_cast<Scalar>(tile_mode_);
  gradient_info.alpha = GetAlpha();
  gradient_info.half_texel = Vector2(0.5 / gradient_texture->GetSize().width,
                                     0.5 / gradient_texture->GetSize().height);

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.matrix = GetInverseMatrix();

  Command cmd;
  cmd.label = "SweepGradientFill";
  cmd.pipeline = renderer.GetSweepGradientFillPipeline(
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
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;
  FS::BindTextureSampler(
      cmd, gradient_texture,
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc));
  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
