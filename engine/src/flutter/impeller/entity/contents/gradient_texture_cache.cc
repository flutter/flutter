// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/gradient_texture_cache.h"

#include <utility>

#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/geometry/gradient.h"

namespace impeller {

void GradientTextureCache::MarkFrameStart() {
  for (auto& entry : entries_) {
    entry.second.used_this_frame = false;
  }
}

void GradientTextureCache::MarkFrameEnd() {
  absl::erase_if(entries_,
                 [](const auto& pair) { return !pair.second.used_this_frame; });
}

std::shared_ptr<Texture> GradientTextureCache::Lookup(
    const std::shared_ptr<Context>& context,
    const std::vector<Color>& colors,
    const std::vector<Scalar>& stops) {
  GradientKey key{.colors = colors, .stops = stops};
  auto it = entries_.find(key);
  if (it != entries_.end()) {
    it->second.used_this_frame = true;
    return it->second.texture;
  }

  GradientData gradient_data = CreateGradientBuffer(colors, stops);
  std::shared_ptr<Texture> texture =
      CreateGradientTexture(gradient_data, context);
  if (!texture) {
    return nullptr;
  }

  entries_[std::move(key)] =
      GradientTextureCacheData{.texture = texture, .used_this_frame = true};
  return texture;
}

}  // namespace impeller
