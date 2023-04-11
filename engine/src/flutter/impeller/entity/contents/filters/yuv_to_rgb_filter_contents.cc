// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/yuv_to_rgb_filter_contents.h"

#include "impeller/core/formats.h"
#include "impeller/entity/contents/anonymous_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/matrix.h"
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

  auto maybe_input_uvs = y_input_snapshot->GetCoverageUVs(coverage);
  if (!maybe_input_uvs.has_value()) {
    return std::nullopt;
  }
  auto input_uvs = maybe_input_uvs.value();

  if (y_input_snapshot->texture->GetTextureDescriptor().format !=
          PixelFormat::kR8UNormInt ||
      uv_input_snapshot->texture->GetTextureDescriptor().format !=
          PixelFormat::kR8G8UNormInt) {
    return std::nullopt;
  }

  //----------------------------------------------------------------------------
  /// Create AnonymousContents for rendering.
  ///
  RenderProc render_proc = [y_input_snapshot, uv_input_snapshot, coverage,
                            yuv_color_space = yuv_color_space_, input_uvs](
                               const ContentContext& renderer,
                               const Entity& entity, RenderPass& pass) -> bool {
    Command cmd;
    cmd.label = "YUV to RGB Filter";
    cmd.stencil_reference = entity.GetStencilDepth();

    auto options = OptionsFromPassAndEntity(pass, entity);
    cmd.pipeline = renderer.GetYUVToRGBFilterPipeline(options);

    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {coverage.origin, input_uvs[0]},
        {{coverage.origin.x + coverage.size.width, coverage.origin.y},
         input_uvs[1]},
        {{coverage.origin.x + coverage.size.width,
          coverage.origin.y + coverage.size.height},
         input_uvs[3]},
        {coverage.origin, input_uvs[0]},
        {{coverage.origin.x + coverage.size.width,
          coverage.origin.y + coverage.size.height},
         input_uvs[3]},
        {{coverage.origin.x, coverage.origin.y + coverage.size.height},
         input_uvs[2]},
    });

    auto& host_buffer = pass.GetTransientsBuffer();
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);
    cmd.BindVertices(vtx_buffer);

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
    frame_info.texture_sampler_y_coord_scale =
        y_input_snapshot->texture->GetYCoordScale();

    FS::FragInfo frag_info;
    frag_info.yuv_color_space = static_cast<Scalar>(yuv_color_space);
    switch (yuv_color_space) {
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

  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage;
  };

  auto contents = AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetStencilDepth(entity.GetStencilDepth());
  sub_entity.SetTransformation(entity.GetTransformation());
  sub_entity.SetBlendMode(entity.GetBlendMode());
  return sub_entity;
}

}  // namespace impeller
