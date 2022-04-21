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

std::optional<Snapshot> Contents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity) const {
  auto bounds = GetCoverage(entity);
  if (!bounds.has_value()) {
    return std::nullopt;
  }

  auto texture = renderer.MakeSubpass(
      ISize::Ceil(bounds->size),
      [&contents = *this, &entity, &bounds](const ContentContext& renderer,
                                            RenderPass& pass) -> bool {
        Entity sub_entity;
        sub_entity.SetBlendMode(Entity::BlendMode::kSourceOver);
        sub_entity.SetTransformation(
            Matrix::MakeTranslation(Vector3(-bounds->origin)) *
            entity.GetTransformation());
        return contents.Render(renderer, sub_entity, pass);
      });

  if (!texture) {
    return std::nullopt;
  }

  return Snapshot{.texture = texture,
                  .transform = Matrix::MakeTranslation(bounds->origin)};
}

}  // namespace impeller
