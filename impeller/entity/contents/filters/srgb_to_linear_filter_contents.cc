// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/srgb_to_linear_filter_contents.h"

#include "impeller/entity/contents/anonymous_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

SrgbToLinearFilterContents::SrgbToLinearFilterContents() = default;

SrgbToLinearFilterContents::~SrgbToLinearFilterContents() = default;

std::optional<Entity> SrgbToLinearFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  using VS = SrgbToLinearFilterPipeline::VertexShader;
  using FS = SrgbToLinearFilterPipeline::FragmentShader;

  auto input_snapshot =
      inputs[0]->GetSnapshot("SrgbToLinear", renderer, entity);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }

  //----------------------------------------------------------------------------
  /// Create AnonymousContents for rendering.
  ///
  RenderProc render_proc = [input_snapshot,
                            absorb_opacity = GetAbsorbOpacity()](
                               const ContentContext& renderer,
                               const Entity& entity, RenderPass& pass) -> bool {
    Command cmd;
    DEBUG_COMMAND_INFO(cmd, "sRGB to Linear Filter");
    cmd.stencil_reference = entity.GetStencilDepth();

    auto options = OptionsFromPassAndEntity(pass, entity);
    cmd.pipeline = renderer.GetSrgbToLinearFilterPipeline(options);

    auto size = input_snapshot->texture->GetSize();

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
    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     entity.GetTransformation() * input_snapshot->transform *
                     Matrix::MakeScale(Vector2(size));
    frame_info.texture_sampler_y_coord_scale =
        input_snapshot->texture->GetYCoordScale();

    FS::FragInfo frag_info;
    frag_info.input_alpha =
        absorb_opacity == ColorFilterContents::AbsorbOpacity::kYes
            ? input_snapshot->opacity
            : 1.0f;

    auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
    FS::BindInputTexture(cmd, input_snapshot->texture, sampler);
    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
    VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

    return pass.AddCommand(std::move(cmd));
  };

  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage.TransformBounds(entity.GetTransformation());
  };

  auto contents = AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetStencilDepth(entity.GetStencilDepth());
  sub_entity.SetBlendMode(entity.GetBlendMode());
  return sub_entity;
}

}  // namespace impeller
