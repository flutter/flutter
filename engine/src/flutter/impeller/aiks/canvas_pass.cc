// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas_pass.h"

#include "impeller/entity/content_renderer.h"

namespace impeller {

CanvasPass::CanvasPass() = default;

CanvasPass::~CanvasPass() = default;

void CanvasPass::AddEntity(Entity entity) {
  entities_.emplace_back(std::move(entity));
}

const std::vector<Entity>& CanvasPass::GetEntities() const {
  return entities_;
}

void CanvasPass::SetEntities(Entities entities) {
  entities_ = std::move(entities);
}

size_t CanvasPass::GetDepth() const {
  size_t max_subpass_depth = 0u;
  for (const auto& subpass : subpasses_) {
    max_subpass_depth = std::max(max_subpass_depth, subpass->GetDepth());
  }
  return max_subpass_depth + 1u;
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

CanvasPass* CanvasPass::GetSuperpass() const {
  return superpass_;
}

const CanvasPass::Subpasses& CanvasPass::GetSubpasses() const {
  return subpasses_;
}

CanvasPass* CanvasPass::AddSubpass(std::unique_ptr<CanvasPass> pass) {
  if (!pass) {
    return nullptr;
  }
  FML_DCHECK(pass->superpass_ == nullptr);
  pass->superpass_ = this;
  return subpasses_.emplace_back(std::move(pass)).get();
}

bool CanvasPass::Render(ContentRenderer& renderer,
                        RenderPass& parent_pass) const {
  for (const auto& entity : entities_) {
    if (!entity.Render(renderer, parent_pass)) {
      return false;
    }
  }
  for (const auto& subpass : subpasses_) {
    if (!subpass->Render(renderer, parent_pass)) {
      return false;
    }
  }
  return true;
}

void CanvasPass::IterateAllEntities(std::function<bool(Entity&)> iterator) {
  if (!iterator) {
    return;
  }

  for (auto& entity : entities_) {
    if (!iterator(entity)) {
      return;
    }
  }

  for (auto& subpass : subpasses_) {
    subpass->IterateAllEntities(iterator);
  }
}

std::unique_ptr<CanvasPass> CanvasPass::Clone() const {
  auto pass = std::make_unique<CanvasPass>();
  pass->SetEntities(entities_);
  for (const auto& subpass : subpasses_) {
    pass->AddSubpass(subpass->Clone());
  }
  return pass;
}

}  // namespace impeller
