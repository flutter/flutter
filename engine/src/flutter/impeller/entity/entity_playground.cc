// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_playground.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/imgui/imgui.h"

namespace impeller {

EntityPlayground::EntityPlayground() = default;

EntityPlayground::~EntityPlayground() = default;

bool EntityPlayground::OpenPlaygroundHere(Entity entity) {
  if (!IsPlaygroundEnabled()) {
    return true;
  }

  ContentContext& content_context = GetContentContext();
  if (!content_context.IsValid()) {
    return false;
  }
  SinglePassCallback callback = [&](RenderPass& pass) -> bool {
    content_context.GetRenderTargetCache()->Start();
    bool result = entity.Render(content_context, pass);
    content_context.GetRenderTargetCache()->End();
    content_context.GetTransientsDataBuffer().Reset();
    content_context.GetTransientsIndexesBuffer().Reset();
    return result;
  };
  return Playground::OpenPlaygroundHere(callback);
}

bool EntityPlayground::OpenPlaygroundHere(EntityPlaygroundCallback callback) {
  if (!IsPlaygroundEnabled()) {
    return true;
  }

  ContentContext& content_context = GetContentContext();
  if (!content_context.IsValid()) {
    return false;
  }
  SinglePassCallback pass_callback = [&](RenderPass& pass) -> bool {
    content_context.GetRenderTargetCache()->Start();
    bool result = callback(content_context, pass);
    content_context.GetRenderTargetCache()->End();
    content_context.GetTransientsDataBuffer().Reset();
    content_context.GetTransientsIndexesBuffer().Reset();
    return result;
  };
  return Playground::OpenPlaygroundHere(pass_callback);
}

}  // namespace impeller
