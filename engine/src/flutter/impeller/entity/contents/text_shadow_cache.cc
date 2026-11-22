// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_shadow_cache.h"

#include <algorithm>
#include <vector>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/sigma.h"

namespace impeller {

// Rounds sigma values for gaussian blur to nearest decimal.
static constexpr int32_t kMaxSigmaDenominator = 10;

TextShadowCache::TextShadowCacheKey::TextShadowCacheKey(
    Scalar p_max_basis,
    Sigma p_sigma,
    Color p_color,
    TextFrameFingerprint p_fingerprint)
    : max_basis(p_max_basis),
      rounded_sigma(Rational(std::round(p_sigma.sigma * kMaxSigmaDenominator),
                             kMaxSigmaDenominator)),
      color(p_color),
      fingerprint(p_fingerprint) {}

TextShadowCache::TextShadowCache(size_t byte_budget)
    : byte_budget_(byte_budget) {}

void TextShadowCache::MarkFrameStart() {
  for (auto& entry : entries_) {
    entry.second.used_this_frame = false;
  }
}

void TextShadowCache::MarkFrameEnd() {
  size_t cache_bytes = 0;
  for (auto it = entries_.begin(); it != entries_.end();) {
    TextShadowCacheData& data = it->second;
    data.unused_frame_count =
        data.used_this_frame ? 0 : data.unused_frame_count + 1;
    if (data.unused_frame_count > kKeepAliveFrameCount) {
      entries_.erase(it++);  // absl's erase() returns void.
      continue;
    }
    cache_bytes += data.byte_size;
    ++it;
  }

  if (cache_bytes <= byte_budget_) {
    return;
  }

  using Iterator = decltype(entries_)::iterator;
  std::vector<Iterator> evictable;
  evictable.reserve(entries_.size());
  for (auto it = entries_.begin(); it != entries_.end(); ++it) {
    if (!it->second.used_this_frame) {
      evictable.push_back(it);
    }
  }
  std::sort(evictable.begin(), evictable.end(), [](Iterator a, Iterator b) {
    return a->second.unused_frame_count > b->second.unused_frame_count;
  });
  for (Iterator it : evictable) {
    if (cache_bytes <= byte_budget_) {
      break;
    }
    cache_bytes -= it->second.byte_size;
    entries_.erase(it);
  }
}

size_t TextShadowCache::GetCacheBytesForTesting() const {
  size_t bytes = 0;
  for (const auto& [key, data] : entries_) {
    bytes += data.byte_size;
  }
  return bytes;
}

std::optional<Entity> TextShadowCache::Lookup(
    const ContentContext& renderer,
    const Entity& entity,
    const std::shared_ptr<FilterContents>& contents,
    const TextShadowCacheKey& text_key) {
  auto it = entries_.find(text_key);

  if (it != entries_.end()) {
    it->second.used_this_frame = true;
    Entity cache_entity = it->second.entity.Clone();
    cache_entity.SetClipDepth(entity.GetClipDepth());
    cache_entity.SetTransform(entity.GetTransform() * it->second.key_matrix);
    return cache_entity;
  }

  std::optional<Rect> filter_coverage = contents->GetCoverage(entity);
  if (!filter_coverage.has_value()) {
    return std::nullopt;
  }

  std::optional<Entity> maybe_entity =
      contents->GetEntity(renderer, entity, contents->GetCoverageHint());
  if (!maybe_entity.has_value()) {
    return std::nullopt;
  }

  // A passthrough of the blur output for kNormal blurs, see
  // TextureContents::RenderToSnapshot. The other blur styles sample more than
  // one texture, so they are flattened into a new one.
  std::optional<Snapshot> snapshot =
      maybe_entity->GetContents()->RenderToSnapshot(renderer, *maybe_entity,
                                                    {});
  if (!snapshot.has_value() || !snapshot->texture) {
    // Not cached: its textures belong to the render target cache and are only
    // valid for this frame.
    maybe_entity->SetClipDepth(entity.GetClipDepth());
    return maybe_entity;
  }
  // The entry samples this texture in later frames, so it must not be reused.
  renderer.GetRenderTargetCache()->RemoveFromCache(snapshot->texture);
  Entity snapshot_entity =
      Entity::FromSnapshot(snapshot.value(), maybe_entity->GetBlendMode());

  // The original entity has a transform matrix A. The snapshot entity has a
  // transform matrix B. We need a function that converts A to B, so that if we
  // render an entity with a slightly different transform matrix A', it appears
  // in the correct position.
  //   A * K = B
  //   A-1 * A * K = A-1 * B
  //   K = A-1 * B
  //
  // The transform matrix K can be computed by inverse A times B. Multiplying
  // any subsequent entity transforms by this matrix will correctly position
  // them.
  Matrix key_matrix =
      entity.GetTransform().Invert() * snapshot_entity.GetTransform();
  entries_[text_key] = TextShadowCacheData{
      .entity = snapshot_entity.Clone(),
      .used_this_frame = true,
      .unused_frame_count = 0,
      .byte_size =
          snapshot->texture->GetTextureDescriptor().GetByteSizeOfAllMipLevels(),
      .key_matrix = key_matrix};

  snapshot_entity.SetClipDepth(entity.GetClipDepth());
  return snapshot_entity;
}

}  // namespace impeller
