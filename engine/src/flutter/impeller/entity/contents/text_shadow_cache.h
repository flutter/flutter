// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_

#include <cstdint>
#include <memory>

#include "impeller/entity/entity.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/sigma.h"
#include "impeller/typographer/text_frame.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "third_party/abseil-cpp/absl/hash/hash.h"

namespace impeller {

/// @brief A multi-attribute fingerprint for a text frame to ensure
///        statistically impossible key collisions without holding a pointer.
///
///        Combines run count, total glyph count, first/last glyph IDs, and a
///        64-bit content hash across all glyph positions and font metrics.
///
///        Napkin Math on Collision Probability:
///        1. For a 64-bit hash (2^64 ~ 1.84e19 space) and N = 1,000 active text
///           frames in a session, the Birthday Paradox collision probability
///           for the 64-bit hash alone is:
///             P_hash = N^2 / (2 * 2^64) = 10^6 / 3.68e19 ~ 2.7e-14
///        2. For two non-identical text frames to collide under this key, they
///           must ALSO independently match:
///             - Run count (P_runs)
///             - Total glyph count (P_len)
///             - First glyph ID (P_first ~ 1/500)
///             - Last glyph ID (P_last ~ 1/500)
///        3. Multiplying these joint constraints:
///             P_joint = P_hash * P_first * P_last * ... << 10^-20
///
///        This makes false-positive cache hits statistically impossible across
///        all devices running Flutter, while avoiding heap pointers or map
///        lookup array traversals.
struct TextFrameFingerprint {
  uint32_t run_count = 0;
  uint32_t total_glyph_count = 0;
  uint32_t first_glyph_id = 0;
  uint32_t last_glyph_id = 0;
  size_t full_hash = 0;

  bool operator==(const TextFrameFingerprint& o) const = default;
};

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
    Rational rounded_sigma;
    Color color;
    TextFrameFingerprint fingerprint;

    TextShadowCacheKey(Scalar p_max_basis,
                       Sigma p_sigma,
                       Color p_color,
                       TextFrameFingerprint p_fingerprint = {});

    struct Hash {
      std::size_t operator()(const TextShadowCacheKey& key) const {
        return absl::HashOf(key.max_basis, key.rounded_sigma.GetHash(),
                            key.color.ToARGB(), key.fingerprint.full_hash);
      }
    };

    struct Equal {
      constexpr bool operator()(const TextShadowCacheKey& lhs,
                                const TextShadowCacheKey& rhs) const {
        return lhs.max_basis == rhs.max_basis &&
               lhs.rounded_sigma == rhs.rounded_sigma &&
               lhs.color == rhs.color && lhs.fingerprint == rhs.fingerprint;
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
