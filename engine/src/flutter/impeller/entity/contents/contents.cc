// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

ContentContextOptions OptionsFromPass(const RenderPass& pass) {
  ContentContextOptions opts;
  opts.sample_count = pass.GetRenderTarget().GetSampleCount();
  return opts;
}

ContentContextOptions OptionsFromPassAndEntity(const RenderPass& pass,
                                               const Entity& entity) {
  ContentContextOptions opts;
  opts.sample_count = pass.GetRenderTarget().GetSampleCount();
  opts.blend_mode = entity.GetBlendMode();
  return opts;
}

Contents::Contents() = default;

Contents::~Contents() = default;

Rect Contents::GetBounds(const Entity& entity) const {
  const auto& transform = entity.GetTransformation();
  auto points = entity.GetPath().GetBoundingBox()->GetPoints();
  for (uint i = 0; i < points.size(); i++) {
    points[i] = transform * points[i];
  }
  return Rect::MakePointBounds({points.begin(), points.end()});
}

std::optional<Contents::Snapshot> Contents::RenderToTexture(
    const ContentContext& renderer,
    const Entity& entity) const {
  auto bounds = GetBounds(entity);

  auto texture = MakeSubpass(
      renderer, ISize(bounds.size),
      [&contents = *this, &entity, &bounds](const ContentContext& renderer,
                                            RenderPass& pass) -> bool {
        Entity sub_entity;
        sub_entity.SetPath(entity.GetPath());
        sub_entity.SetBlendMode(Entity::BlendMode::kSource);
        sub_entity.SetTransformation(
            Matrix::MakeTranslation(Vector3(-bounds.origin)) *
            entity.GetTransformation());
        return contents.Render(renderer, sub_entity, pass);
      });

  if (!texture.has_value()) {
    return std::nullopt;
  }

  return Snapshot{.texture = texture.value(), .position = bounds.origin};
}

using SubpassCallback = std::function<bool(const ContentContext&, RenderPass&)>;

std::optional<std::shared_ptr<Texture>> Contents::MakeSubpass(
    const ContentContext& renderer,
    ISize texture_size,
    SubpassCallback subpass_callback) {
  auto context = renderer.GetContext();

  auto subpass_target = RenderTarget::CreateOffscreen(*context, texture_size);
  auto subpass_texture = subpass_target.GetRenderTargetTexture();
  if (!subpass_texture) {
    return std::nullopt;
  }

  auto sub_command_buffer = context->CreateRenderCommandBuffer();
  sub_command_buffer->SetLabel("Offscreen Contents Command Buffer");
  if (!sub_command_buffer) {
    return std::nullopt;
  }

  auto sub_renderpass = sub_command_buffer->CreateRenderPass(subpass_target);
  if (!sub_renderpass) {
    return std::nullopt;
  }
  sub_renderpass->SetLabel("OffscreenContentsPass");

  if (!subpass_callback(renderer, *sub_renderpass)) {
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

}  // namespace impeller
