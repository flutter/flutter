// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/linear_to_srgb_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

LinearToSrgbFilterContents::LinearToSrgbFilterContents() = default;

LinearToSrgbFilterContents::~LinearToSrgbFilterContents() = default;

std::optional<Entity> LinearToSrgbFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  using VS = LinearToSrgbFilterPipeline::VertexShader;
  using FS = LinearToSrgbFilterPipeline::FragmentShader;

  auto input_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }

  ContentContext::SubpassCallback callback = [&](const ContentContext& renderer,
                                                 RenderPass& pass) {
    Command cmd;
    cmd.label = "Linear to sRGB Filter";

    auto options = OptionsFromPass(pass);
    options.blend_mode = BlendMode::kSource;
    cmd.pipeline = renderer.GetLinearToSrgbFilterPipeline(options);

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
        input_snapshot->texture->GetYCoordScale();

    FS::FragInfo frag_info;
    frag_info.input_alpha = GetAbsorbOpacity() ? input_snapshot->opacity : 1.0f;

    auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
    FS::BindInputTexture(cmd, input_snapshot->texture, sampler);
    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
    VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

    return pass.AddCommand(std::move(cmd));
  };

  auto out_texture =
      renderer.MakeSubpass(input_snapshot->texture->GetSize(), callback);
  if (!out_texture) {
    return std::nullopt;
  }
  out_texture->SetLabel("LinearToSrgb Texture");

  return Contents::EntityFromSnapshot(
      Snapshot{.texture = out_texture,
               .transform = input_snapshot->transform,
               .sampler_descriptor = input_snapshot->sampler_descriptor,
               .opacity = GetAbsorbOpacity() ? 1.0f : input_snapshot->opacity},
      entity.GetBlendMode(), entity.GetStencilDepth());
}

}  // namespace impeller
