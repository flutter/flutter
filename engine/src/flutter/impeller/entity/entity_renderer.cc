// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/entity_renderer.h"

#include "flutter/fml/trace_event.h"
#include "impeller/entity/content_renderer.h"

namespace impeller {

EntityRenderer::EntityRenderer(std::shared_ptr<Context> context)
    : context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  content_renderer_ = std::make_unique<ContentRenderer>(context_);
  if (!content_renderer_->IsValid()) {
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
                                    const std::vector<Entity>& entities) {
  if (!IsValid()) {
    return false;
  }

  for (const auto& entity : entities) {
    if (auto contents = entity.GetContents()) {
      if (!contents->Render(*content_renderer_, entity, surface,
                            onscreen_pass)) {
        return false;
      }
    }
  }

  return true;
}

}  // namespace impeller
