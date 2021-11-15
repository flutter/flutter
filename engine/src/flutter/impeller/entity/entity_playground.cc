// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_playground.h"

namespace impeller {

EntityPlayground::EntityPlayground() = default;

EntityPlayground::~EntityPlayground() = default;

bool EntityPlayground::OpenPlaygroundHere(Entity entity) {
  if (!renderer_) {
    renderer_ = std::make_unique<EntityRenderer>(GetContext());
    if (!renderer_) {
      return false;
    }
  }
  Renderer::RenderCallback callback = [&](const Surface& surface,
                                          RenderPass& pass) -> bool {
    std::vector<Entity> entities = {entity};
    return renderer_->RenderEntities(surface, pass, entities);
  };
  return Playground::OpenPlaygroundHere(callback);
}

}  // namespace impeller
