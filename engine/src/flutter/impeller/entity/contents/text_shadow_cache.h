// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_

#include <cstdint>
#include <memory>
#include <unordered_map>

#include "impeller/entity/entity.h"
#include "impeller/geometry/scalar.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

class TextShadowCache {
 public:
  TextShadowCache() = default;

  ~TextShadowCache() = default;

  struct TextShadowCacheKey {
    Scalar max_basis;
    int64_t identifier;
    bool is_single_glyph;
    Font font;

    TextShadowCacheKey(Scalar p_max_basis,
                       int64_t p_identifier,
                       bool p_is_single_glyph,
                       const Font& p_font)
        : max_basis(p_max_basis),
          identifier(p_identifier),
          is_single_glyph(p_is_single_glyph),
          font(p_font) {}

    struct Hash {
      std::size_t operator()(const TextShadowCacheKey& key) const {
        return fml::HashCombine(key.max_basis, key.identifier,
                                key.is_single_glyph, key.font.GetHash());
      }
    };

    struct Equal {
      constexpr bool operator()(const TextShadowCacheKey& lhs,
                                const TextShadowCacheKey& rhs) const {
        return lhs.max_basis == rhs.max_basis &&
               lhs.identifier == rhs.identifier &&
               lhs.is_single_glyph == rhs.is_single_glyph &&
               lhs.font.IsEqual(rhs.font);
      }
    };
  };

  void MarkFrameStart();

  void MarkFrameEnd();

  std::optional<Entity> Lookup(const ContentContext& renderer,
                               const Entity& entity,
                               const std::shared_ptr<FilterContents>& contents,
                               const TextShadowCacheKey&);

 private:
  struct TextShadowCacheData {
    Entity entity;
    bool used_this_frame = true;
    Matrix key_matrix;
  };

  std::unordered_map<TextShadowCacheKey,
                     TextShadowCacheData,
                     TextShadowCacheKey::Hash,
                     TextShadowCacheKey::Equal>
      entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_SHADOW_CACHE_H_
