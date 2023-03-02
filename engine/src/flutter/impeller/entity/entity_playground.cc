// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_playground.h"

#include "impeller/entity/contents/content_context.h"

#include "third_party/imgui/imgui.h"

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
  SinglePassCallback callback = [&](RenderPass& pass) -> bool {
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
  SinglePassCallback pass_callback = [&](RenderPass& pass) -> bool {
    static bool wireframe = false;
    if (ImGui::IsKeyPressed(ImGuiKey_Z)) {
      wireframe = !wireframe;
      content_context.SetWireframe(wireframe);
    }
    return callback(content_context, pass);
  };
  return Playground::OpenPlaygroundHere(pass_callback);
}

}  // namespace impeller
