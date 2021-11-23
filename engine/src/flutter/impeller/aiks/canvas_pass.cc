// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass.h"

#include "impeller/entity/content_renderer.h"

namespace impeller {

CanvasPass::CanvasPass() = default;

CanvasPass::~CanvasPass() = default;

void CanvasPass::PushEntity(Entity entity) {
  entities_.emplace_back(std::move(entity));
}

const std::vector<Entity>& CanvasPass::GetEntities() const {
  return entities_;
}

Rect CanvasPass::GetCoverageRect() const {
  std::optional<Point> min, max;
  for (const auto& entity : entities_) {
    auto coverage = entity.GetPath().GetMinMaxCoveragePoints();
    if (!coverage.has_value()) {
      continue;
    }
    if (!min.has_value()) {
      min = coverage->first;
    }
    if (!max.has_value()) {
      max = coverage->second;
    }
    min = min->Min(coverage->first);
    max = max->Max(coverage->second);
  }
  if (!min.has_value() || !max.has_value()) {
    return {};
  }
  const auto diff = *max - *min;
  return {min->x, min->y, diff.x, diff.y};
}

const CanvasPass::Subpasses& CanvasPass::GetSubpasses() const {
  return subpasses_;
}

bool CanvasPass::AddSubpass(CanvasPass pass) {
  subpasses_.emplace_back(std::move(pass));
  return true;
}

bool CanvasPass::Render(ContentRenderer& renderer,
                        RenderPass& parent_pass) const {
  for (const auto& entity : entities_) {
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }
  return true;
}

}  // namespace impeller
