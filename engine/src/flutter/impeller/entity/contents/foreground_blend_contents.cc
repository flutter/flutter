// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "foreground_blend_contents.h"

#include "flutter/impeller/entity/contents/content_context.h"
#include "flutter/impeller/renderer/render_pass.h"
#include "flutter/impeller/renderer/sampler_library.h"

namespace impeller {

AdvancedForegroundBlendContents::AdvancedForegroundBlendContents() {}

AdvancedForegroundBlendContents::~AdvancedForegroundBlendContents() {}

void AdvancedForegroundBlendContents::SetBlendMode(BlendMode blend_mode) {
  FML_DCHECK(blend_mode > Entity::kLastPipelineBlendMode);
  blend_mode_ = blend_mode;
}

void AdvancedForegroundBlendContents::SetSrcInput(
    std::shared_ptr<FilterInput> input) {
  input_ = std::move(input);
}

void AdvancedForegroundBlendContents::SetForegroundColor(Color color) {
  foreground_color_ = color;
}

void AdvancedForegroundBlendContents::SetCoverage(Rect rect) {
  rect_ = rect;
}

std::optional<Rect> AdvancedForegroundBlendContents::GetCoverage(
    const Entity& entity) const {
  return rect_.TransformBounds(entity.GetTransformation());
}

bool AdvancedForegroundBlendContents::Render(const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass) const {
  using VS = BlendScreenPipeline::VertexShader;
  using FS = BlendScreenPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto dst_snapshot = input_->GetSnapshot(renderer, entity);
  if (!dst_snapshot.has_value()) {
    return false;
  }
  auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(rect_);
  if (!maybe_dst_uvs.has_value()) {
    return false;
  }
  auto dst_uvs = maybe_dst_uvs.value();

  auto size = rect_.size;
  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), dst_uvs[0], dst_uvs[0]},
      {Point(size.width, 0), dst_uvs[1], dst_uvs[1]},
      {Point(size.width, size.height), dst_uvs[3], dst_uvs[3]},
      {Point(0, 0), dst_uvs[0], dst_uvs[0]},
      {Point(size.width, size.height), dst_uvs[3], dst_uvs[3]},
      {Point(0, size.height), dst_uvs[2], dst_uvs[2]},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  Command cmd;
  cmd.label = "Foreground Advanced Blend Filter";
  cmd.BindVertices(vtx_buffer);
  cmd.stencil_reference = entity.GetStencilDepth();
  auto options = OptionsFromPass(pass);

  switch (blend_mode_) {
    case BlendMode::kScreen:
      cmd.pipeline = renderer.GetBlendScreenPipeline(options);
      break;
    case BlendMode::kOverlay:
      cmd.pipeline = renderer.GetBlendOverlayPipeline(options);
      break;
    case BlendMode::kDarken:
      cmd.pipeline = renderer.GetBlendDarkenPipeline(options);
      break;
    case BlendMode::kLighten:
      cmd.pipeline = renderer.GetBlendLightenPipeline(options);
      break;
    case BlendMode::kColorDodge:
      cmd.pipeline = renderer.GetBlendColorDodgePipeline(options);
      break;
    case BlendMode::kColorBurn:
      cmd.pipeline = renderer.GetBlendColorBurnPipeline(options);
      break;
    case BlendMode::kHardLight:
      cmd.pipeline = renderer.GetBlendHardLightPipeline(options);
      break;
    case BlendMode::kSoftLight:
      cmd.pipeline = renderer.GetBlendSoftLightPipeline(options);
      break;
    case BlendMode::kDifference:
      cmd.pipeline = renderer.GetBlendDifferencePipeline(options);
      break;
    case BlendMode::kExclusion:
      cmd.pipeline = renderer.GetBlendExclusionPipeline(options);
      break;
    case BlendMode::kMultiply:
      cmd.pipeline = renderer.GetBlendMultiplyPipeline(options);
      break;
    case BlendMode::kHue:
      cmd.pipeline = renderer.GetBlendHuePipeline(options);
      break;
    case BlendMode::kSaturation:
      cmd.pipeline = renderer.GetBlendSaturationPipeline(options);
      break;
    case BlendMode::kColor:
      cmd.pipeline = renderer.GetBlendColorPipeline(options);
      break;
    case BlendMode::kLuminosity:
      cmd.pipeline = renderer.GetBlendLuminosityPipeline(options);
      break;
    default:
      return false;
  }

  FS::BlendInfo blend_info;
  VS::FrameInfo frame_info;

  auto dst_sampler_descriptor = dst_snapshot->sampler_descriptor;
  if (renderer.GetDeviceCapabilities().SupportsDecalTileMode()) {
    dst_sampler_descriptor.width_address_mode = SamplerAddressMode::kDecal;
    dst_sampler_descriptor.height_address_mode = SamplerAddressMode::kDecal;
  }
  auto dst_sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
      dst_sampler_descriptor);
  FS::BindTextureSamplerDst(cmd, dst_snapshot->texture, dst_sampler);
  frame_info.dst_y_coord_scale = dst_snapshot->texture->GetYCoordScale();
  blend_info.dst_input_alpha = dst_snapshot->opacity;

  blend_info.color_factor = 1;
  blend_info.color = foreground_color_;
  // This texture will not be sampled from due to the color factor. But
  // this is present so that validation doesn't trip on a missing
  // binding.
  FS::BindTextureSamplerSrc(cmd, dst_snapshot->texture, dst_sampler);

  auto blend_uniform = host_buffer.EmplaceUniform(blend_info);
  FS::BindBlendInfo(cmd, blend_uniform);

  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);

  return pass.AddCommand(cmd);
}

}  // namespace impeller
