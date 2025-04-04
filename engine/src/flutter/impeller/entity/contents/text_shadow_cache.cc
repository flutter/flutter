// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_shadow_cache.h"

#include "fml/closure.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/sigma.h"

namespace impeller {

// Rounds sigma values for gaussian blur to nearest decimal.
static constexpr int32_t kMaxSigmaDenominator = 10;

TextShadowCache::TextShadowCacheKey::TextShadowCacheKey(Scalar p_max_basis,
                                                        int64_t p_identifier,
                                                        bool p_is_single_glyph,
                                                        const Font& p_font,
                                                        Sigma p_sigma)
    : max_basis(p_max_basis),
      identifier(p_identifier),
      is_single_glyph(p_is_single_glyph),
      font(p_font),
      rounded_sigma(Rational(std::round(p_sigma.sigma * kMaxSigmaDenominator),
                             kMaxSigmaDenominator)) {}

void TextShadowCache::MarkFrameStart() {
  for (auto& entry : entries_) {
    entry.second.used_this_frame = false;
  }
}

void TextShadowCache::MarkFrameEnd() {
  absl::erase_if(entries_,
                 [](const auto& pair) { return !pair.second.used_this_frame; });
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

  // Execute the filter to produce a snapshot that can be resued on subsequent
  // frames. To prevent this texture from being re-used by the render target
  // cache, we temporarily disable any RT caching.
  renderer.GetRenderTargetCache()->DisableCache();
  fml::ScopedCleanupClosure closure(
      [&] { renderer.GetRenderTargetCache()->EnableCache(); });
  std::optional<Entity> maybe_entity =
      contents->GetEntity(renderer, entity, contents->GetCoverageHint());
  if (!maybe_entity.has_value()) {
    return std::nullopt;
  }

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
      entity.GetTransform().Invert() * maybe_entity->GetTransform();
  entries_[text_key] =
      TextShadowCacheData{.entity = maybe_entity.value().Clone(),
                          .used_this_frame = true,
                          .key_matrix = key_matrix};

  maybe_entity->SetClipDepth(entity.GetClipDepth());
  return maybe_entity;
}

}  // namespace impeller
