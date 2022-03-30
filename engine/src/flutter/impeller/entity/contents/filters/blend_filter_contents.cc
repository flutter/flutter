// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/blend_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_input.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

BlendFilterContents::BlendFilterContents() {
  SetBlendMode(Entity::BlendMode::kSourceOver);
}

BlendFilterContents::~BlendFilterContents() = default;

using PipelineProc =
    std::shared_ptr<Pipeline> (ContentContext::*)(ContentContextOptions) const;

template <typename VS, typename FS>
static bool AdvancedBlend(const FilterInput::Vector& inputs,
                          const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass,
                          const Rect& bounds,
                          PipelineProc pipeline_proc) {
  if (inputs.size() < 2) {
    return false;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  auto size = pass.GetRenderTargetSize();
  VertexBufferBuilder<typename VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), Point(0, 0)},
      {Point(size.width, 0), Point(1, 0)},
      {Point(size.width, size.height), Point(1, 1)},
      {Point(0, 0), Point(0, 0)},
      {Point(size.width, size.height), Point(1, 1)},
      {Point(0, size.height), Point(0, 1)},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  std::shared_ptr<Pipeline> pipeline =
      std::invoke(pipeline_proc, renderer, options);

  Command cmd;
  cmd.label = "Advanced Blend Filter";
  cmd.BindVertices(vtx_buffer);
  cmd.pipeline = std::move(pipeline);

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(size);

  auto dst_snapshot = inputs[1]->GetSnapshot(renderer, entity);
  FS::BindTextureSamplerSrc(cmd, dst_snapshot->texture, sampler);
  frame_info.dst_uv_transform =
      Matrix::MakeTranslation(-(dst_snapshot->position - bounds.origin) /
                              size) *
      Matrix::MakeScale(
          Vector3(Size(size) / Size(dst_snapshot->texture->GetSize())));

  auto src_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  FS::BindTextureSamplerDst(cmd, src_snapshot->texture, sampler);
  frame_info.src_uv_transform =
      Matrix::MakeTranslation(-(src_snapshot->position - bounds.origin) /
                              size) *
      Matrix::MakeScale(
          Vector3(Size(size) / Size(src_snapshot->texture->GetSize())));

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);
  pass.AddCommand(cmd);

  return true;
}

void BlendFilterContents::SetBlendMode(Entity::BlendMode blend_mode) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " assigned to BlendFilterContents.";
  }

  blend_mode_ = blend_mode;

  if (blend_mode > Entity::BlendMode::kLastPipelineBlendMode) {
    static_assert(Entity::BlendMode::kLastAdvancedBlendMode ==
                  Entity::BlendMode::kScreen);

    switch (blend_mode) {
      case Entity::BlendMode::kScreen:
        advanced_blend_proc_ = [](const FilterInput::Vector& inputs,
                                  const ContentContext& renderer,
                                  const Entity& entity, RenderPass& pass,
                                  const Rect& bounds) {
          PipelineProc p = &ContentContext::GetTextureBlendScreenPipeline;
          return AdvancedBlend<TextureBlendScreenPipeline::VertexShader,
                               TextureBlendScreenPipeline::FragmentShader>(
              inputs, renderer, entity, pass, bounds, p);
        };
        break;
      default:
        FML_UNREACHABLE();
    }
  }
}

static bool BasicBlend(const FilterInput::Vector& inputs,
                       const ContentContext& renderer,
                       const Entity& entity,
                       RenderPass& pass,
                       const Rect& bounds,
                       Entity::BlendMode basic_blend) {
  using VS = TextureBlendPipeline::VertexShader;
  using FS = TextureBlendPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto size = pass.GetRenderTargetSize();
  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), Point(0, 0)},
      {Point(size.width, 0), Point(1, 0)},
      {Point(size.width, size.height), Point(1, 1)},
      {Point(0, 0), Point(0, 0)},
      {Point(size.width, size.height), Point(1, 1)},
      {Point(0, size.height), Point(0, 1)},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  // Draw the first texture using kSource.

  Command cmd;
  cmd.label = "Basic Blend Filter";
  cmd.BindVertices(vtx_buffer);
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetTextureBlendPipeline(options);
  {
    auto input = inputs[0]->GetSnapshot(renderer, entity);
    FS::BindTextureSamplerSrc(cmd, input->texture, sampler);

    VS::FrameInfo frame_info;
    frame_info.mvp =
        Matrix::MakeOrthographic(size) *
        Matrix::MakeTranslation(input->position - bounds.origin) *
        Matrix::MakeScale(Size(input->texture->GetSize()) / Size(size));

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);
  }
  pass.AddCommand(cmd);

  if (inputs.size() < 2) {
    return true;
  }

  // Write subsequent textures using the selected blend mode.

  options.blend_mode = basic_blend;
  cmd.pipeline = renderer.GetTextureBlendPipeline(options);

  for (auto texture_i = inputs.begin() + 1; texture_i < inputs.end();
       texture_i++) {
    auto input = texture_i->get()->GetSnapshot(renderer, entity);
    FS::BindTextureSamplerSrc(cmd, input->texture, sampler);

    VS::FrameInfo frame_info;
    frame_info.mvp = frame_info.mvp =
        Matrix::MakeOrthographic(size) *
        Matrix::MakeTranslation(input->position - bounds.origin) *
        Matrix::MakeScale(Size(input->texture->GetSize()) / Size(size));

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);
    pass.AddCommand(cmd);
  }

  return true;
}

bool BlendFilterContents::RenderFilter(const FilterInput::Vector& inputs,
                                       const ContentContext& renderer,
                                       const Entity& entity,
                                       RenderPass& pass,
                                       const Rect& bounds) const {
  if (inputs.empty()) {
    return true;
  }

  if (inputs.size() == 1) {
    // Nothing to blend.
    return BasicBlend(inputs, renderer, entity, pass, bounds,
                      Entity::BlendMode::kSource);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastPipelineBlendMode) {
    return BasicBlend(inputs, renderer, entity, pass, bounds, blend_mode_);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastAdvancedBlendMode) {
    return advanced_blend_proc_(inputs, renderer, entity, pass, bounds);
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
