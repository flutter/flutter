// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_TEXTURE_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_TEXTURE_CACHE_H_

#include <cstddef>
#include <memory>
#include <utility>
#include <vector>

#include "impeller/core/texture.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/scalar.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"

namespace impeller {

class Context;

/// @brief A cache of gradient ramp textures, keyed on the colors and stops
///        that produced them.
///
/// Gradient ramps are retained for as long as they are used at least once per
/// frame.
class GradientTextureCache {
 public:
  GradientTextureCache() = default;

  ~GradientTextureCache() = default;

  /// @brief Mark all cached gradient textures as unused this frame.
  void MarkFrameStart();

  /// @brief Remove all gradient textures that were not referenced at least
  ///        once.
  void MarkFrameEnd();

  /// @brief Look up the gradient ramp texture for the given colors and stops.
  ///
  /// If the texture is not present in the cache, it is created and inserted.
  /// Returns nullptr if the texture could not be created.
  std::shared_ptr<Texture> Lookup(const std::shared_ptr<Context>& context,
                                  const std::vector<Color>& colors,
                                  const std::vector<Scalar>& stops);

  // Visible for testing.
  size_t GetCacheSizeForTesting() const { return entries_.size(); }

 private:
  GradientTextureCache(const GradientTextureCache&) = delete;

  GradientTextureCache& operator=(const GradientTextureCache&) = delete;

  /// @brief The colors and stops that define a gradient ramp.
  struct GradientKey {
    std::vector<Color> colors;
    std::vector<Scalar> stops;

    bool operator==(const GradientKey&) const = default;

    template <typename H>
    friend H AbslHashValue(H h, const GradientKey& key) {
      return H::combine(std::move(h), key.colors, key.stops);
    }
  };

  struct GradientTextureCacheData {
    std::shared_ptr<Texture> texture;
    bool used_this_frame = true;
  };

  absl::flat_hash_map<GradientKey, GradientTextureCacheData> entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_GRADIENT_TEXTURE_CACHE_H_
