// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass.h"

namespace impeller {

CanvasPass::CanvasPass() = default;

CanvasPass::~CanvasPass() = default;

void CanvasPass::PushEntity(Entity entity) {
  ops_.emplace_back(std::move(entity));
}

const std::vector<Entity>& CanvasPass::GetPassEntities() const {
  return ops_;
}

void CanvasPass::SetPostProcessingEntity(Entity entity) {
  post_processing_entity_ = std::move(entity);
}

const Entity& CanvasPass::GetPostProcessingEntity() const {
  return post_processing_entity_;
}

Rect CanvasPass::GetCoverageRect() const {
  std::optional<Point> min, max;
  for (const auto& entity : ops_) {
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

}  // namespace impeller
