// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_playground.h"

#include "impeller/entity/content_context.h"

namespace impeller {

EntityPlayground::EntityPlayground() = default;

EntityPlayground::~EntityPlayground() = default;

bool EntityPlayground::OpenPlaygroundHere(Entity entity) {
  if (!Playground::is_enabled()) {
    return true;
  }

  ContentContext content_context(GetContext());
  if (!content_context.IsValid()) {
    return false;
  }
  Renderer::RenderCallback callback = [&](RenderPass& pass) -> bool {
    return entity.Render(content_context, pass);
  };
  return Playground::OpenPlaygroundHere(callback);
}

bool EntityPlayground::OpenPlaygroundHere(EntityPlaygroundCallback callback) {
  if (!Playground::is_enabled()) {
    return true;
  }

  ContentContext content_context(GetContext());
  if (!content_context.IsValid()) {
    return false;
  }
  Renderer::RenderCallback render_callback = [&](RenderPass& pass) -> bool {
    return callback(content_context, pass);
  };
  return Playground::OpenPlaygroundHere(render_callback);
}

}  // namespace impeller
