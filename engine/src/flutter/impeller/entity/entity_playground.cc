// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_playground.h"

#include "impeller/entity/content_context.h"

namespace impeller {

EntityPlayground::EntityPlayground() = default;

EntityPlayground::~EntityPlayground() = default;

bool EntityPlayground::OpenPlaygroundHere(Entity entity) {
  ContentContext context_context(GetContext());
  if (!context_context.IsValid()) {
    return false;
  }
  Renderer::RenderCallback callback = [&](RenderPass& pass) -> bool {
    return entity.Render(context_context, pass);
  };
  return Playground::OpenPlaygroundHere(callback);
}

}  // namespace impeller
