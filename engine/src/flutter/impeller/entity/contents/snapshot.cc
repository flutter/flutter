// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/snapshot.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/texture_contents.h"

namespace impeller {

std::optional<Snapshot> Snapshot::FromTransformedTexture(
    const ContentContext& renderer,
    const Entity& entity,
    std::shared_ptr<Texture> texture) {
  Rect bounds = entity.GetTransformedPathBounds();

  auto result = renderer.MakeSubpass(
      ISize(bounds.size),
      [&texture, &entity, bounds](const ContentContext& renderer,
                                  RenderPass& pass) -> bool {
        TextureContents contents;
        contents.SetTexture(texture);
        contents.SetSourceRect(Rect::MakeSize(Size(texture->GetSize())));
        Entity sub_entity;
        sub_entity.SetPath(entity.GetPath());
        sub_entity.SetBlendMode(Entity::BlendMode::kSource);
        sub_entity.SetTransformation(
            Matrix::MakeTranslation(Vector3(-bounds.origin)) *
            entity.GetTransformation());
        return contents.Render(renderer, sub_entity, pass);
      });
  if (!result) {
    return std::nullopt;
  }

  return Snapshot{.texture = result, .position = bounds.origin};
}

}  // namespace impeller
