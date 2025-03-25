// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_shadow_cache.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

void TextShadowCache::MarkFrameStart() {
  for (auto& entry : entries_) {
    entry.second.used_this_frame = false;
  }
}

void TextShadowCache::MarkFrameEnd() {
  std::vector<int> to_remove;
  for (auto& entry : entries_) {
    if (!entry.second.used_this_frame) {
      to_remove.push_back(entry.first);
    }
  }
  for (auto key : to_remove) {
    entries_.erase(key);
  }
}

bool TextShadowCache::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass,
                             const std::shared_ptr<FilterContents>& contents,
                             int text_key) {
  std::unordered_map<int, TextShadowCacheData>::iterator it =
      entries_.find(text_key);
  if (it != entries_.end()) {
    it->second.used_this_frame = true;
    Entity& cache_entity = it->second.entity;
    cache_entity.SetClipDepth(entity.GetClipDepth());
    auto old_transform = cache_entity.GetTransform();
    cache_entity.SetTransform(old_transform * entity.GetTransform());
    auto result = cache_entity.Render(renderer, pass);
    cache_entity.SetTransform(old_transform);
    return result;
  }

  auto filter_coverage = contents->GetCoverage(entity);
  if (!filter_coverage.has_value()) {
    return true;
  }

  // Run the filter.
  auto maybe_entity =
      contents->GetEntity(renderer, entity, contents->GetCoverageHint());
  if (!maybe_entity.has_value()) {
    return true;
  }
  entries_[text_key] = TextShadowCacheData{
      .entity = maybe_entity.value().Clone(), .used_this_frame = true};

  maybe_entity->SetClipDepth(entity.GetClipDepth());
  return maybe_entity->Render(renderer, pass);
}

}  // namespace impeller
