// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/entity_renderer.h"

#include "flutter/fml/trace_event.h"
#include "flutter/impeller/entity/entity_renderer_impl.h"

namespace impeller {

EntityRenderer::EntityRenderer(std::shared_ptr<Context> context)
    : renderer_(std::make_unique<EntityRendererImpl>(std::move(context))) {
  if (!renderer_->IsValid()) {
    return;
  }
  is_valid_ = true;
}

EntityRenderer::~EntityRenderer() = default;

bool EntityRenderer::IsValid() const {
  return is_valid_;
}

bool EntityRenderer::RenderEntities(const Surface& surface,
                                    RenderPass& onscreen_pass,
                                    const std::vector<Entity>& entities) const {
  if (!IsValid()) {
    return false;
  }

  for (const auto& entity : entities) {
    if (renderer_->RenderEntity(surface, onscreen_pass, entity) ==
        EntityRendererImpl::RenderResult::kFailure) {
      return false;
    }
  }

  return true;
}

}  // namespace impeller
