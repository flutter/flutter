// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/texture.h"

namespace impeller {

Texture::Texture(TextureDescriptor desc, id<MTLTexture> texture)
    : desc_(std::move(desc)), texture_(texture) {
  if (!desc_.IsValid() || !texture_) {
    return;
  }

  is_valid_ = true;
}

Texture::~Texture() = default;

bool Texture::SetContents(const uint8_t* contents,
                          size_t length,
                          size_t mip_level) {
  if (!IsValid() || !contents) {
    return false;
  }

  FML_CHECK(false);
  return false;

  // MTLRegionMake2D(NSUInteger x, NSUInteger y, NSUInteger width,
  //                 NSUInteger height)

  // [texture_ replaceRegion:(MTLRegion)
  //             mipmapLevel:(NSUInteger)withBytes:(nonnull const
  //             void*)bytesPerRow
  //                        :(NSUInteger)];
}

ISize Texture::GetSize() const {
  return {static_cast<ISize::Type>(texture_.width),
          static_cast<ISize::Type>(texture_.height)};
}

id<MTLTexture> Texture::GetMTLTexture() const {
  return texture_;
}

bool Texture::IsValid() const {
  return is_valid_;
}

}  // namespace impeller
