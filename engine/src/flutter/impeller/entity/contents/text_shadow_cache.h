// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_

#include <cstdint>
#include <memory>

#include "flutter/third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/sigma.h"

namespace impeller {

/// @brief A cache for blurred text that re-uses these across frames.
///
/// Text shadows are generally stable, but expensive to compute as we use a
/// full gaussian blur. This class caches these shadows by text blob identifier
/// and holds them for at least one frame.
///
/// Additionally, there is an optimization for a single glyph (generally an
/// Icon) that uses the content itself as a key.
///
/// If there was a cheaper method of text frame identity, or a per-glyph caching
/// system this could be more efficient. As it exists, this mostly ameliorate
/// severe performance degradation for glyph shadows but does not provide
/// substantially better performance than Skia.
class TextShadowCache {
 public:
  TextShadowCache() = default;

  ~TextShadowCache() = default;

  /// @brief A key to look up cached glyph textures.
  struct TextShadowCacheKey {
    Scalar max_basis;
    int64_t identifier;
    bool is_single_glyph;
    Font font;
    Rational rounded_sigma;

    TextShadowCacheKey(Scalar p_max_basis,
                       int64_t p_identifier,
                       bool p_is_single_glyph,
                       const Font& p_font,
                       Sigma p_sigma);

    struct Hash {
      std::size_t operator()(const TextShadowCacheKey& key) const {
        return fml::HashCombine(key.max_basis, key.identifier,
                                key.is_single_glyph, key.font.GetHash(),
                                key.rounded_sigma.GetHash());
      }
    };

    struct Equal {
      constexpr bool operator()(const TextShadowCacheKey& lhs,
                                const TextShadowCacheKey& rhs) const {
        return lhs.max_basis == rhs.max_basis &&
               lhs.identifier == rhs.identifier &&
               lhs.is_single_glyph == rhs.is_single_glyph &&
               lhs.font.IsEqual(rhs.font) &&
               lhs.rounded_sigma == rhs.rounded_sigma;
      }
    };
  };

  /// @brief Mark all glyph textures as unused this frame.
  void MarkFrameStart();

  /// @brief Remove all glyph textures that were not referenced at least once.
  void MarkFrameEnd();

  /// @brief Lookup the entity in the cache with the given filter/text contents,
  ///        returning the new entity to render.
  ///
  /// If the entity is not present, render and place in the cache.
  std::optional<Entity> Lookup(const ContentContext& renderer,
                               const Entity& entity,
                               const std::shared_ptr<FilterContents>& contents,
                               const TextShadowCacheKey&);

  // Visible for testing.
  size_t GetCacheSizeForTesting() const { return entries_.size(); }

 private:
  TextShadowCache(const TextShadowCache&) = delete;

  TextShadowCache& operator=(const TextShadowCache&) = delete;

  struct TextShadowCacheData {
    Entity entity;
    bool used_this_frame = true;
    Matrix key_matrix;
  };

  absl::flat_hash_map<TextShadowCacheKey,
                      TextShadowCacheData,
                      TextShadowCacheKey::Hash,
                      TextShadowCacheKey::Equal>
      entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
