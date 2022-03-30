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

  // Because this filter is intended to be used with only one input parameter,
  // and GetBounds just increases the input size by a factor of the direction,
  // we we can just scale up the UVs by the same amount and don't need to worry
  // about mapping the UVs to the destination rect (like we do in
  // BlendFilterContents).

  auto input = inputs[0]->GetSnapshot(renderer, entity);
  auto input_size = input->texture->GetSize();

  auto transformed_blur =
      entity.GetTransformation().TransformDirection(blur_vector_);

  auto uv_offset = transformed_blur.Abs() / input_size;
  // LTRB
  Scalar uv[4] = {
      -uv_offset.x,
      -uv_offset.y,
      1 + uv_offset.x,
      1 + uv_offset.y,
  };

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  auto size = pass.GetRenderTargetSize();
  vtx_builder.AddVertices({
      {Point(0, 0), Point(uv[0], uv[1])},
      {Point(size.width, 0), Point(uv[2], uv[1])},
      {Point(size.width, size.height), Point(uv[2], uv[3])},
      {Point(0, 0), Point(uv[0], uv[1])},
      {Point(size.width, size.height), Point(uv[2], uv[3])},
      {Point(0, size.height), Point(uv[0], uv[3])},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  VS::FrameInfo frame_info;
  frame_info.texture_size = Point(input_size);
  frame_info.blur_radius = transformed_blur.GetLength();
  frame_info.blur_direction = transformed_blur.Normalize();

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  Command cmd;
  cmd.label = "Gaussian Blur Filter";
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetGaussianBlurPipeline(options);
  cmd.BindVertices(vtx_buffer);

  FS::BindTextureSampler(cmd, input->texture, sampler);

  frame_info.mvp = Matrix::MakeOrthographic(size);
  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);

  return pass.AddCommand(cmd);
}

Rect DirectionalGaussianBlurFilterContents::GetBounds(
    const Entity& entity) const {
  auto bounds = FilterContents::GetBounds(entity);
  auto transformed_blur =
      entity.GetTransformation().TransformDirection(blur_vector_).Abs();
  auto extent = bounds.size + transformed_blur * 2;
  return Rect(bounds.origin - transformed_blur, Size(extent.x, extent.y));
}

}  // namespace impeller
