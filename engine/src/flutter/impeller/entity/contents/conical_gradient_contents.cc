// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "conical_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/gradient.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

ConicalGradientContents::ConicalGradientContents() = default;

ConicalGradientContents::~ConicalGradientContents() = default;

void ConicalGradientContents::SetCenterAndRadius(Point center, Scalar radius) {
  center_ = center;
  radius_ = radius;
}

void ConicalGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

void ConicalGradientContents::SetDither(bool dither) {
  dither_ = dither;
}

void ConicalGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
}

void ConicalGradientContents::SetStops(std::vector<Scalar> stops) {
  stops_ = std::move(stops);
}

const std::vector<Color>& ConicalGradientContents::GetColors() const {
  return colors_;
}

const std::vector<Scalar>& ConicalGradientContents::GetStops() const {
  return stops_;
}

void ConicalGradientContents::SetFocus(std::optional<Point> focus,
                                       Scalar radius) {
  focus_ = focus;
  focus_radius_ = radius;
}

bool ConicalGradientContents::Render(const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsSSBO()) {
    return RenderSSBO(renderer, entity, pass);
  }
  return RenderTexture(renderer, entity, pass);
}

bool ConicalGradientContents::RenderSSBO(const ContentContext& renderer,
                                         const Entity& entity,
                                         RenderPass& pass) const {
  using VS = ConicalGradientSSBOFillPipeline::VertexShader;
  using FS = ConicalGradientSSBOFillPipeline::FragmentShader;

  FS::FragInfo frag_info;
  frag_info.center = center_;
  frag_info.radius = radius_;
  frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
  frag_info.decal_border_color = decal_border_color_;
  frag_info.alpha = GetOpacityFactor();
  frag_info.dither = dither_;
  if (focus_) {
    frag_info.focus = focus_.value();
    frag_info.focus_radius = focus_radius_;
  } else {
    frag_info.focus = center_;
    frag_info.focus_radius = 0.0;
  }

  auto& host_buffer = pass.GetTransientsBuffer();
  auto colors = CreateGradientColors(colors_, stops_);

  frag_info.colors_length = colors.size();
  auto color_buffer =
      host_buffer.Emplace(colors.data(), colors.size() * sizeof(StopData),
                          DefaultUniformAlignment());

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.matrix = GetInverseEffectTransform();

  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "ConicalGradientSSBOFill");
  cmd.stencil_reference = entity.GetClipDepth();

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);
  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetConicalGradientSSBOFillPipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));
  FS::BindColorData(cmd, color_buffer);
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  if (geometry_result.prevent_overdraw) {
    auto restore = ClipRestoreContents();
    restore.SetRestoreCoverage(GetCoverage(entity));
    return restore.Render(renderer, entity, pass);
  }
  return true;
}

bool ConicalGradientContents::RenderTexture(const ContentContext& renderer,
                                            const Entity& entity,
                                            RenderPass& pass) const {
  using VS = ConicalGradientFillPipeline::VertexShader;
  using FS = ConicalGradientFillPipeline::FragmentShader;

  auto gradient_data = CreateGradientBuffer(colors_, stops_);
  auto gradient_texture =
      CreateGradientTexture(gradient_data, renderer.GetContext());
  if (gradient_texture == nullptr) {
    return false;
  }

  FS::FragInfo frag_info;
  frag_info.center = center_;
  frag_info.radius = radius_;
  frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
  frag_info.decal_border_color = decal_border_color_;
  frag_info.texture_sampler_y_coord_scale = gradient_texture->GetYCoordScale();
  frag_info.alpha = GetOpacityFactor();
  frag_info.half_texel = Vector2(0.5 / gradient_texture->GetSize().width,
                                 0.5 / gradient_texture->GetSize().height);
  if (focus_) {
    frag_info.focus = focus_.value();
    frag_info.focus_radius = focus_radius_;
  } else {
    frag_info.focus = center_;
    frag_info.focus_radius = 0.0;
  }

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  frame_info.matrix = GetInverseEffectTransform();

  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "ConicalGradientFill");
  cmd.stencil_reference = entity.GetClipDepth();

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetConicalGradientFillPipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));
  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;
  FS::BindTextureSampler(
      cmd, gradient_texture,
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  if (geometry_result.prevent_overdraw) {
    auto restore = ClipRestoreContents();
    restore.SetRestoreCoverage(GetCoverage(entity));
    return restore.Render(renderer, entity, pass);
  }
  return true;
}

bool ConicalGradientContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  for (Color& color : colors_) {
    color = color_filter_proc(color);
  }
  decal_border_color_ = color_filter_proc(decal_border_color_);
  return true;
}

}  // namespace impeller
