// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/filter_contents.h"

#include <algorithm>
#include <cmath>
#include <optional>

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

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

std::shared_ptr<FilterContents> FilterContents::MakeDirectionalGaussianBlur(
    InputVariant input_texture,
    Scalar radius,
    Vector2 direction,
    bool clip_border) {
  auto blur = std::make_shared<DirectionalGaussianBlurFilterContents>();
  blur->SetInputTextures({input_texture});
  blur->SetRadius(radius);
  blur->SetDirection(direction);
  blur->SetClipBorder(clip_border);
  return blur;
}

std::shared_ptr<FilterContents> FilterContents::MakeGaussianBlur(
    InputVariant input_texture,
    Scalar radius,
    bool clip_border) {
  auto x_blur = MakeDirectionalGaussianBlur(input_texture, radius, Point(1, 0),
                                            clip_border);
  return MakeDirectionalGaussianBlur(x_blur, radius, Point(0, 1), false);
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
  auto output_size = GetOutputSize(input_textures_);
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
  return GetOutputSize(input_textures_);
}

ISize FilterContents::GetOutputSize(const InputTextures& input_textures) const {
  if (auto filter =
          std::get_if<std::shared_ptr<FilterContents>>(&input_textures[0])) {
    return filter->get()->GetOutputSize(input_textures);
  }

  if (auto texture =
          std::get_if<std::shared_ptr<Texture>>(&input_textures[0])) {
    return texture->get()->GetSize();
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
