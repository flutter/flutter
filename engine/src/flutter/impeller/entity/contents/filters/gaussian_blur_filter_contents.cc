// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

DirectionalGaussianBlurFilterContents::DirectionalGaussianBlurFilterContents() =
    default;

DirectionalGaussianBlurFilterContents::
    ~DirectionalGaussianBlurFilterContents() = default;

void DirectionalGaussianBlurFilterContents::SetRadius(Scalar radius) {
  radius_ = std::max(radius, 1e-3f);
}

void DirectionalGaussianBlurFilterContents::SetDirection(Vector2 direction) {
  direction_ = direction.Normalize();
}

void DirectionalGaussianBlurFilterContents::SetClipBorder(bool clip) {
  clip_ = clip;
}

bool DirectionalGaussianBlurFilterContents::RenderFilter(
    const std::vector<std::shared_ptr<Texture>>& input_textures,
    const ContentContext& renderer,
    RenderPass& pass) const {
  using VS = GaussianBlurPipeline::VertexShader;
  using FS = GaussianBlurPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  ISize size = FilterContents::GetOutputSize();
  Point uv_offset = clip_ ? (Point(radius_, radius_) / size) : Point();
  // LTRB
  Scalar uv[4] = {
      -uv_offset.x,
      -uv_offset.y,
      1 + uv_offset.x,
      1 + uv_offset.y,
  };

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
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
  frame_info.mvp = Matrix::MakeOrthographic(size);
  frame_info.texture_size = Point(size);
  frame_info.blur_radius = radius_;
  frame_info.blur_direction = direction_;

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  Command cmd;
  cmd.label = "Gaussian Blur Filter";
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetGaussianBlurPipeline(options);
  cmd.BindVertices(vtx_buffer);
  VS::BindFrameInfo(cmd, uniform_view);
  for (const auto& texture : input_textures) {
    FS::BindTextureSampler(cmd, texture, sampler);
    pass.AddCommand(cmd);
  }

  return true;
}

ISize DirectionalGaussianBlurFilterContents::GetOutputSize(
    const InputTextures& input_textures) const {
  ISize size;
  if (auto filter =
          std::get_if<std::shared_ptr<FilterContents>>(&input_textures[0])) {
    size = filter->get()->GetOutputSize();
  } else if (auto texture =
                 std::get_if<std::shared_ptr<Texture>>(&input_textures[0])) {
    size = texture->get()->GetSize();
  } else {
    FML_UNREACHABLE();
  }

  return size + (clip_ ? ISize(radius_ * 2, radius_ * 2) : ISize());
}

}  // namespace impeller
