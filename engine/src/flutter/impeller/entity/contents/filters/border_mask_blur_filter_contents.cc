// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/border_mask_blur_filter_contents.h"
#include "impeller/entity/contents/content_context.h"

#include "impeller/entity/contents/contents.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

BorderMaskBlurFilterContents::BorderMaskBlurFilterContents() = default;

BorderMaskBlurFilterContents::~BorderMaskBlurFilterContents() = default;

void BorderMaskBlurFilterContents::SetSigma(Sigma sigma_x, Sigma sigma_y) {
  sigma_x_ = sigma_x;
  sigma_y_ = sigma_y;
}

void BorderMaskBlurFilterContents::SetBlurStyle(BlurStyle blur_style) {
  blur_style_ = blur_style;

  switch (blur_style) {
    case FilterContents::BlurStyle::kNormal:
      src_color_factor_ = false;
      inner_blur_factor_ = true;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kSolid:
      src_color_factor_ = true;
      inner_blur_factor_ = false;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kOuter:
      src_color_factor_ = false;
      inner_blur_factor_ = false;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kInner:
      src_color_factor_ = false;
      inner_blur_factor_ = true;
      outer_blur_factor_ = false;
      break;
  }
}

bool BorderMaskBlurFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    const Rect& coverage) const {
  if (inputs.empty()) {
    return true;
  }

  using VS = BorderMaskBlurPipeline::VertexShader;
  using FS = BorderMaskBlurPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto input_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  if (!input_snapshot.has_value()) {
    return true;
  }
  auto maybe_input_uvs = input_snapshot->GetCoverageUVs(coverage);
  if (!maybe_input_uvs.has_value()) {
    return true;
  }
  auto input_uvs = maybe_input_uvs.value();

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), input_uvs[0]},
      {Point(1, 0), input_uvs[1]},
      {Point(1, 1), input_uvs[3]},
      {Point(0, 0), input_uvs[0]},
      {Point(1, 1), input_uvs[3]},
      {Point(0, 1), input_uvs[2]},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  Command cmd;
  cmd.label = "Border Mask Blur Filter";
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetBorderMaskBlurPipeline(options);
  cmd.BindVertices(vtx_buffer);

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));
  frame_info.sigma_uv = Vector2(sigma_x_.sigma, sigma_y_.sigma).Abs() /
                        input_snapshot->texture->GetSize();
  frame_info.src_factor = src_color_factor_;
  frame_info.inner_blur_factor = inner_blur_factor_;
  frame_info.outer_blur_factor = outer_blur_factor_;
  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
  FS::BindTextureSampler(cmd, input_snapshot->texture, sampler);

  return pass.AddCommand(std::move(cmd));
}

std::optional<Rect> BorderMaskBlurFilterContents::GetFilterCoverage(
    const FilterInput::Vector& inputs,
    const Entity& entity) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  auto coverage = inputs[0]->GetCoverage(entity);
  if (!coverage.has_value()) {
    return std::nullopt;
  }
  auto transform = inputs[0]->GetTransform(entity);
  auto transformed_blur_vector =
      transform.TransformDirection(Vector2(Radius{sigma_x_}.radius, 0)).Abs() +
      transform.TransformDirection(Vector2(0, Radius{sigma_y_}.radius)).Abs();
  auto extent = coverage->size + transformed_blur_vector * 2;
  return Rect(coverage->origin - transformed_blur_vector,
              Size(extent.x, extent.y));
}

}  // namespace impeller
