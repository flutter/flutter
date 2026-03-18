// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_TEXTURE_CACHE_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_TEXTURE_CACHE_H_

#include <map>
#include <memory>

#include "flutter/display_list/image/dl_image.h"
#include "impeller/core/texture.h"

namespace impeller {

using TextureCache =
    std::map<const flutter::DlImage*, std::shared_ptr<Texture>>;

inline std::shared_ptr<Texture> GetCachedTexture(
    const flutter::DlImage* image,
    const std::shared_ptr<Context>& context,
    TextureCache* image_cache) {
  if (!image) {
    return nullptr;
  }
  if (image_cache) {
    auto it = image_cache->find(image);
    if (it != image_cache->end()) {
      return it->second;
    }
  }
  auto texture = image->GetImpellerTexture(context);
  if (image_cache && texture) {
    (*image_cache)[image] = texture;
  }
  return texture;
}

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_TEXTURE_CACHE_H_
