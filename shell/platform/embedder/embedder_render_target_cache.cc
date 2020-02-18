// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_cache.h"

namespace flutter {

EmbedderRenderTargetCache::EmbedderRenderTargetCache() = default;

EmbedderRenderTargetCache::~EmbedderRenderTargetCache() = default;

std::pair<EmbedderRenderTargetCache::RenderTargets,
          EmbedderExternalView::ViewIdentifierSet>
EmbedderRenderTargetCache::GetExistingTargetsInCache(
    const EmbedderExternalView::PendingViews& pending_views) {
  RenderTargets resolved_render_targets;
  EmbedderExternalView::ViewIdentifierSet unmatched_identifiers;

  for (const auto& view : pending_views) {
    const auto& external_view = view.second;
    if (!external_view->HasEngineRenderedContents()) {
      continue;
    }
    auto& compatible_targets =
        cached_render_targets_[external_view->CreateRenderTargetDescriptor()];
    if (compatible_targets.size() == 0) {
      unmatched_identifiers.insert(view.first);
    } else {
      std::unique_ptr<EmbedderRenderTarget> target =
          std::move(compatible_targets.top());
      compatible_targets.pop();
      resolved_render_targets[view.first] = std::move(target);
    }
  }
  return {std::move(resolved_render_targets), std::move(unmatched_identifiers)};
}

void EmbedderRenderTargetCache::ClearAllRenderTargetsInCache() {
  cached_render_targets_.clear();
}

void EmbedderRenderTargetCache::CacheRenderTarget(
    std::unique_ptr<EmbedderRenderTarget> target) {
  if (target == nullptr) {
    return;
  }
  auto surface = target->GetRenderSurface();
  EmbedderExternalView::RenderTargetDescriptor desc{
      SkISize::Make(surface->width(), surface->height())};
  cached_render_targets_[desc].push(std::move(target));
}

size_t EmbedderRenderTargetCache::GetCachedTargetsCount() const {
  size_t count = 0;
  for (const auto& targets : cached_render_targets_) {
    count += targets.second.size();
  }
  return count;
}

}  // namespace flutter
