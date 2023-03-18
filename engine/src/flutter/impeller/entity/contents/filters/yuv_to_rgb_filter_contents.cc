// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/yuv_to_rgb_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/matrix.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

// clang-format off
constexpr Matrix kMatrixBT601LimitedRange = {
    1.164,  1.164, 1.164, 0.0,
      0.0, -0.392, 2.017, 0.0,
    1.596, -0.813,   0.0, 0.0,
      0.0,    0.0,   0.0, 1.0
};

constexpr Matrix kMatrixBT601FullRange = {
      1.0,    1.0,   1.0, 0.0,
      0.0, -0.344, 1.772, 0.0,
    1.402, -0.714,   0.0, 0.0,
      0.0,    0.0,   0.0, 1.0
};
// clang-format on

YUVToRGBFilterContents::YUVToRGBFilterContents() = default;

YUVToRGBFilterContents::~YUVToRGBFilterContents() = default;

void YUVToRGBFilterContents::SetYUVColorSpace(YUVColorSpace yuv_color_space) {
  yuv_color_space_ = yuv_color_space;
}

std::optional<Entity> YUVToRGBFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage) const {
  if (inputs.size() < 2) {
    return std::nullopt;
  }

  using VS = YUVToRGBFilterPipeline::VertexShader;
  using FS = YUVToRGBFilterPipeline::FragmentShader;

  auto y_input_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  auto uv_input_snapshot = inputs[1]->GetSnapshot(renderer, entity);
  if (!y_input_snapshot.has_value() || !uv_input_snapshot.has_value()) {
    return std::nullopt;
  }

  if (y_input_snapshot->texture->GetTextureDescriptor().format !=
          PixelFormat::kR8UNormInt ||
      uv_input_snapshot->texture->GetTextureDescriptor().format !=
          PixelFormat::kR8G8UNormInt) {
    return std::nullopt;
  }

  ContentContext::SubpassCallback callback = [&](const ContentContext& renderer,
                                                 RenderPass& pass) {
    Command cmd;
    cmd.label = "YUV to RGB Filter";

    auto options = OptionsFromPass(pass);
    options.blend_mode = BlendMode::kSource;
    cmd.pipeline = renderer.GetYUVToRGBFilterPipeline(options);

    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {Point(0, 0)},
        {Point(1, 0)},
        {Point(1, 1)},
        {Point(0, 0)},
        {Point(1, 1)},
        {Point(0, 1)},
    });

    auto& host_buffer = pass.GetTransientsBuffer();
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);
    cmd.BindVertices(vtx_buffer);

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));
    frame_info.texture_sampler_y_coord_scale =
        y_input_snapshot->texture->GetYCoordScale();

    FS::FragInfo frag_info;
    frag_info.yuv_color_space = static_cast<Scalar>(yuv_color_space_);
    switch (yuv_color_space_) {
      case YUVColorSpace::kBT601LimitedRange:
        frag_info.matrix = kMatrixBT601LimitedRange;
        break;
      case YUVColorSpace::kBT601FullRange:
        frag_info.matrix = kMatrixBT601FullRange;
        break;
    }

    auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
    FS::BindYTexture(cmd, y_input_snapshot->texture, sampler);
    FS::BindUvTexture(cmd, uv_input_snapshot->texture, sampler);

    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
    VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

    return pass.AddCommand(std::move(cmd));
  };

  auto out_texture = renderer.MakeSubpass(
      "YUV to RGB Filter", y_input_snapshot->texture->GetSize(), callback);
  if (!out_texture) {
    return std::nullopt;
  }

  return Entity::FromSnapshot(Snapshot{.texture = out_texture},
                              entity.GetBlendMode(), entity.GetStencilDepth());
}

}  // namespace impeller
