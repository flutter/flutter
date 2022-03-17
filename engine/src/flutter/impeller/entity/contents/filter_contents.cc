// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "filter_contents.h"

#include <memory>
#include <optional>
#include <variant>

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

/*******************************************************************************
 ******* FilterContents
 ******************************************************************************/

std::shared_ptr<FilterContents> FilterContents::MakeBlend(
    Entity::BlendMode blend_mode,
    InputTextures input_textures) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " passed to FilterContents::MakeBlend.";
    return nullptr;
  }

  if (input_textures.size() < 2 ||
      blend_mode <= Entity::BlendMode::kLastPipelineBlendMode) {
    auto blend = std::make_shared<BlendFilterContents>();
    blend->SetInputTextures(input_textures);
    blend->SetBlendMode(blend_mode);
    return blend;
  }

  if (blend_mode <= Entity::BlendMode::kLastAdvancedBlendMode) {
    InputVariant blend = input_textures[0];
    for (auto in_i = input_textures.begin() + 1; in_i < input_textures.end();
         in_i++) {
      auto new_blend = std::make_shared<BlendFilterContents>();
      new_blend->SetInputTextures({blend, *in_i});
      new_blend->SetBlendMode(blend_mode);
      blend = new_blend;
    }
    return std::get<std::shared_ptr<FilterContents>>(blend);
  }

  FML_UNREACHABLE();
}

FilterContents::FilterContents() = default;

FilterContents::~FilterContents() = default;

void FilterContents::SetInputTextures(InputTextures input_textures) {
  input_textures_ = std::move(input_textures);
}

bool FilterContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  // Run the filter.

  auto maybe_texture = RenderFilterToTexture(renderer, entity, pass);
  if (!maybe_texture.has_value()) {
    return false;
  }
  auto& texture = maybe_texture.value();

  // Draw the resulting texture to the given destination rect, respecting the
  // transform and clip stack.

  auto contents = std::make_shared<TextureContents>();
  contents->SetTexture(texture);
  contents->SetSourceRect(IRect::MakeSize(texture->GetSize()));

  return contents->Render(renderer, entity, pass);
}

std::optional<std::shared_ptr<Texture>> FilterContents::RenderFilterToTexture(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto output_size = GetOutputSize();
  if (output_size.IsZero()) {
    return std::nullopt;
  }

  // Resolve all inputs as textures.

  std::vector<std::shared_ptr<Texture>> input_textures;
  input_textures.reserve(input_textures_.size());
  for (const auto& input : input_textures_) {
    if (auto filter = std::get_if<std::shared_ptr<FilterContents>>(&input)) {
      auto texture =
          filter->get()->RenderFilterToTexture(renderer, entity, pass);
      if (!texture.has_value()) {
        return std::nullopt;
      }
      input_textures.push_back(std::move(texture.value()));
    } else if (auto texture = std::get_if<std::shared_ptr<Texture>>(&input)) {
      input_textures.push_back(*texture);
    } else {
      FML_UNREACHABLE();
    }
  }

  // Create a new texture and render the filter to it.

  auto context = renderer.GetContext();

  auto subpass_target = RenderTarget::CreateOffscreen(*context, output_size);
  auto subpass_texture = subpass_target.GetRenderTargetTexture();
  if (!subpass_texture) {
    return std::nullopt;
  }

  auto sub_command_buffer = context->CreateRenderCommandBuffer();
  sub_command_buffer->SetLabel("Offscreen Filter Command Buffer");
  if (!sub_command_buffer) {
    return std::nullopt;
  }

  auto sub_renderpass = sub_command_buffer->CreateRenderPass(subpass_target);
  if (!sub_renderpass) {
    return std::nullopt;
  }
  sub_renderpass->SetLabel("OffscreenFilterPass");

  if (!RenderFilter(input_textures, renderer, *sub_renderpass)) {
    return std::nullopt;
  }

  if (!sub_renderpass->EncodeCommands(*context->GetTransientsAllocator())) {
    return std::nullopt;
  }

  if (!sub_command_buffer->SubmitCommands()) {
    return std::nullopt;
  }

  return subpass_texture;
}

ISize FilterContents::GetOutputSize() const {
  if (input_textures_.empty()) {
    return {};
  }

  if (auto filter =
          std::get_if<std::shared_ptr<FilterContents>>(&input_textures_[0])) {
    return filter->get()->GetOutputSize();
  }

  if (auto texture =
          std::get_if<std::shared_ptr<Texture>>(&input_textures_[0])) {
    return texture->get()->GetSize();
  }

  FML_UNREACHABLE();
}

/*******************************************************************************
 ******* BlendFilterContents
 ******************************************************************************/

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
