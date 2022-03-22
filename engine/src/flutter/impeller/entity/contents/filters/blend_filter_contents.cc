// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/blend_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
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
static void AdvancedBlendPass(std::shared_ptr<Texture> input_d,
                              std::shared_ptr<Texture> input_s,
                              std::shared_ptr<const Sampler> sampler,
                              const ContentContext& renderer,
                              RenderPass& pass,
                              Command& cmd) {}

template <typename VS, typename FS>
static bool AdvancedBlend(
    const std::vector<std::shared_ptr<Texture>>& input_textures,
    const ContentContext& renderer,
    RenderPass& pass,
    PipelineProc pipeline_proc) {
  if (input_textures.size() < 2) {
    return false;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  VertexBufferBuilder<typename VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), Point(0, 0)},
      {Point(1, 0), Point(1, 0)},
      {Point(1, 1), Point(1, 1)},
      {Point(0, 0), Point(0, 0)},
      {Point(1, 1), Point(1, 1)},
      {Point(0, 1), Point(0, 1)},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  std::shared_ptr<Pipeline> pipeline =
      std::invoke(pipeline_proc, renderer, options);

  Command cmd;
  cmd.label = "Advanced Blend Filter";
  cmd.BindVertices(vtx_buffer);
  cmd.pipeline = std::move(pipeline);
  VS::BindFrameInfo(cmd, uniform_view);

  FS::BindTextureSamplerDst(cmd, input_textures[0], sampler);
  FS::BindTextureSamplerSrc(cmd, input_textures[1], sampler);
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
        advanced_blend_proc_ =
            [](const std::vector<std::shared_ptr<Texture>>& input_textures,
               const ContentContext& renderer, RenderPass& pass) {
              PipelineProc p = &ContentContext::GetTextureBlendScreenPipeline;
              return AdvancedBlend<TextureBlendScreenPipeline::VertexShader,
                                   TextureBlendScreenPipeline::FragmentShader>(
                  input_textures, renderer, pass, p);
            };
        break;
      default:
        FML_UNREACHABLE();
    }
  }
}

static bool BasicBlend(
    const std::vector<std::shared_ptr<Texture>>& input_textures,
    const ContentContext& renderer,
    RenderPass& pass,
    Entity::BlendMode basic_blend) {
  using VS = TextureBlendPipeline::VertexShader;
  using FS = TextureBlendPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), Point(0, 0)},
      {Point(1, 0), Point(1, 0)},
      {Point(1, 1), Point(1, 1)},
      {Point(0, 0), Point(0, 0)},
      {Point(1, 1), Point(1, 1)},
      {Point(0, 1), Point(0, 1)},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  // Draw the first texture using kSource.

  Command cmd;
  cmd.label = "Basic Blend Filter";
  cmd.BindVertices(vtx_buffer);
  auto options = OptionsFromPass(pass);
  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetTextureBlendPipeline(options);
  FS::BindTextureSamplerSrc(cmd, input_textures[0], sampler);
  VS::BindFrameInfo(cmd, uniform_view);
  pass.AddCommand(cmd);

  if (input_textures.size() < 2) {
    return true;
  }

  // Write subsequent textures using the selected blend mode.

  options.blend_mode = basic_blend;
  cmd.pipeline = renderer.GetTextureBlendPipeline(options);

  for (auto texture_i = input_textures.begin() + 1;
       texture_i < input_textures.end(); texture_i++) {
    FS::BindTextureSamplerSrc(cmd, *texture_i, sampler);
    pass.AddCommand(cmd);
  }

  return true;
}

bool BlendFilterContents::RenderFilter(
    const std::vector<std::shared_ptr<Texture>>& input_textures,
    const ContentContext& renderer,
    RenderPass& pass) const {
  if (input_textures.empty()) {
    return true;
  }

  if (input_textures.size() == 1) {
    // Nothing to blend.
    return BasicBlend(input_textures, renderer, pass,
                      Entity::BlendMode::kSource);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastPipelineBlendMode) {
    return BasicBlend(input_textures, renderer, pass, blend_mode_);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastAdvancedBlendMode) {
    return advanced_blend_proc_(input_textures, renderer, pass);
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
