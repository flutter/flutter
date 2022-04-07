// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"

#include <valarray>

#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

DirectionalGaussianBlurFilterContents::DirectionalGaussianBlurFilterContents() =
    default;

DirectionalGaussianBlurFilterContents::
    ~DirectionalGaussianBlurFilterContents() = default;

void DirectionalGaussianBlurFilterContents::SetBlurVector(Vector2 blur_vector) {
  if (blur_vector.GetLengthSquared() < kEhCloseEnough) {
    blur_vector_ = Vector2(0, kEhCloseEnough);
    return;
  }
  blur_vector_ = blur_vector;
}

void DirectionalGaussianBlurFilterContents::SetBlurStyle(BlurStyle blur_style) {
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

void DirectionalGaussianBlurFilterContents::SetSourceOverride(
    FilterInput::Ref alpha_mask) {
  source_override_ = alpha_mask;
}

bool DirectionalGaussianBlurFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    const Rect& bounds) const {
  if (inputs.empty()) {
    return true;
  }

  using VS = GaussianBlurPipeline::VertexShader;
  using FS = GaussianBlurPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto input = inputs[0]->GetSnapshot(renderer, entity);
  if (!input.has_value()) {
    return true;
  }

  auto input_bounds = inputs[0]->GetCoverage(entity);
  if (!input_bounds.has_value() || input_bounds->IsEmpty()) {
    return true;
  }
  auto filter_bounds = GetCoverage(entity);
  if (!filter_bounds.has_value() || filter_bounds->IsEmpty()) {
    FML_LOG(ERROR) << "The gaussian blur filter coverage is missing or empty "
                      "even though the filter's input has coverage.";
    return false;
  }

  auto transformed_blur =
      entity.GetTransformation().TransformDirection(blur_vector_);

  // LTRB
  Scalar uv[4] = {
      (filter_bounds->GetLeft() - input_bounds->GetLeft()) /
          input_bounds->size.width,
      (filter_bounds->GetTop() - input_bounds->GetTop()) /
          input_bounds->size.height,
      1 + (filter_bounds->GetRight() - input_bounds->GetRight()) /
              input_bounds->size.width,
      1 + (filter_bounds->GetBottom() - input_bounds->GetBottom()) /
              input_bounds->size.height,
  };

  auto source = source_override_ ? source_override_ : inputs[0];
  auto source_texture = source->GetSnapshot(renderer, entity);
  auto source_bounds = source->GetCoverage(entity);
  if (!source_texture.has_value() || !source_bounds.has_value() ||
      source_bounds->IsEmpty()) {
    VALIDATION_LOG << "The gaussian blur source override has no coverage.";
    return false;
  }

  // LTRB
  Scalar uv_src[4] = {
      (filter_bounds->GetLeft() - source_bounds->GetLeft()) /
          source_bounds->size.width,
      (filter_bounds->GetTop() - source_bounds->GetTop()) /
          source_bounds->size.height,
      1 + (filter_bounds->GetRight() - source_bounds->GetRight()) /
              source_bounds->size.width,
      1 + (filter_bounds->GetBottom() - source_bounds->GetBottom()) /
              source_bounds->size.height,
  };

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), Point(uv[0], uv[1]), Point(uv_src[0], uv_src[1])},
      {Point(1, 0), Point(uv[2], uv[1]), Point(uv_src[2], uv_src[1])},
      {Point(1, 1), Point(uv[2], uv[3]), Point(uv_src[2], uv_src[3])},
      {Point(0, 0), Point(uv[0], uv[1]), Point(uv_src[0], uv_src[1])},
      {Point(1, 1), Point(uv[2], uv[3]), Point(uv_src[2], uv_src[3])},
      {Point(0, 1), Point(uv[0], uv[3]), Point(uv_src[0], uv_src[3])},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  VS::FrameInfo frame_info;
  frame_info.texture_size = Point(input_bounds->size);
  frame_info.blur_radius = transformed_blur.GetLength();
  frame_info.blur_direction = transformed_blur.Normalize();
  frame_info.src_factor = src_color_factor_;
  frame_info.inner_blur_factor = inner_blur_factor_;
  frame_info.outer_blur_factor = outer_blur_factor_;

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  Command cmd;
  cmd.label = "Gaussian Blur Filter";
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetGaussianBlurPipeline(options);
  cmd.BindVertices(vtx_buffer);

  FS::BindTextureSampler(cmd, input->texture, sampler);
  FS::BindAlphaMaskSampler(cmd, source_texture->texture, sampler);

  frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));
  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);

  return pass.AddCommand(cmd);
}

std::optional<Rect> DirectionalGaussianBlurFilterContents::GetCoverage(
    const Entity& entity) const {
  auto bounds = FilterContents::GetCoverage(entity);
  if (!bounds.has_value()) {
    return std::nullopt;
  }

  auto transformed_blur =
      entity.GetTransformation().TransformDirection(blur_vector_).Abs();
  auto extent = bounds->size + transformed_blur * 2;
  return Rect(bounds->origin - transformed_blur, Size(extent.x, extent.y));
}

}  // namespace impeller
