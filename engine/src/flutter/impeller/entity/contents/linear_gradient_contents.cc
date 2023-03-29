// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "linear_gradient_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/entity.h"
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
  if (renderer.GetDeviceCapabilities().SupportsSSBO()) {
    return RenderSSBO(renderer, entity, pass);
  }
  return RenderTexture(renderer, entity, pass);
}

bool LinearGradientContents::RenderTexture(const ContentContext& renderer,
                                           const Entity& entity,
                                           RenderPass& pass) const {
  using VS = LinearGradientFillPipeline::VertexShader;
  using FS = LinearGradientFillPipeline::FragmentShader;

  auto gradient_data = CreateGradientBuffer(colors_, stops_);
  auto gradient_texture =
      CreateGradientTexture(gradient_data, renderer.GetContext());
  if (gradient_texture == nullptr) {
    return false;
  }

  FS::FragInfo frag_info;
  frag_info.start_point = start_point_;
  frag_info.end_point = end_point_;
  frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
  frag_info.texture_sampler_y_coord_scale = gradient_texture->GetYCoordScale();
  frag_info.alpha = GetOpacity();
  frag_info.half_texel = Vector2(0.5 / gradient_texture->GetSize().width,
                                 0.5 / gradient_texture->GetSize().height);

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  frame_info.matrix = GetInverseMatrix();

  Command cmd;
  cmd.label = "LinearGradientFill";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetLinearGradientFillPipeline(options);

  cmd.BindVertices(geometry_result.vertex_buffer);
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));
  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;
  FS::BindTextureSampler(
      cmd, std::move(gradient_texture),
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

bool LinearGradientContents::RenderSSBO(const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass) const {
  using VS = LinearGradientSSBOFillPipeline::VertexShader;
  using FS = LinearGradientSSBOFillPipeline::FragmentShader;

  FS::FragInfo frag_info;
  frag_info.start_point = start_point_;
  frag_info.end_point = end_point_;
  frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
  frag_info.alpha = GetOpacity();

  auto& host_buffer = pass.GetTransientsBuffer();
  auto colors = CreateGradientColors(colors_, stops_);

  frag_info.colors_length = colors.size();
  auto color_buffer =
      host_buffer.Emplace(colors.data(), colors.size() * sizeof(StopData),
                          DefaultUniformAlignment());

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.matrix = GetInverseMatrix();

  Command cmd;
  cmd.label = "LinearGradientSSBOFill";
  cmd.stencil_reference = entity.GetStencilDepth();

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);
  auto options = OptionsFromPassAndEntity(pass, entity);
  if (geometry_result.prevent_overdraw) {
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }
  options.primitive_type = geometry_result.type;
  cmd.pipeline = renderer.GetLinearGradientSSBOFillPipeline(options);

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

}  // namespace impeller
