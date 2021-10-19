// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/texture.h"

namespace impeller {

Texture::Texture(TextureDescriptor desc, id<MTLTexture> texture)
    : desc_(std::move(desc)), texture_(texture) {
  if (!desc_.IsValid() || !texture_) {
    return;
  }

  if (desc_.size != GetSize()) {
    FML_DLOG(ERROR)
        << "The texture and its descriptor disagree about its size.";
    return;
  }

  is_valid_ = true;
}

Texture::~Texture() = default;

void Texture::SetLabel(const std::string_view& label) {
  [texture_ setLabel:@(label.data())];
}

bool Texture::SetContents(const uint8_t* contents, size_t length) {
  if (!IsValid() || !contents) {
    return false;
  }

  // Out of bounds access.
  if (length != desc_.GetSizeOfBaseMipLevel()) {
    return false;
  }

  // TODO(csg): Perhaps the storage mode should be added to the texture
  // descriptor so that invalid region replacements on potentially non-host
  // visible textures are disallowed. The annoying bit about the API below is
  // that there seems to be no error handling guidance.
  const auto region =
      MTLRegionMake2D(0u, 0u, desc_.size.width, desc_.size.height);
  [texture_ replaceRegion:region                  //
              mipmapLevel:0u                      //
                withBytes:contents                //
              bytesPerRow:desc_.GetBytesPerRow()  //
  ];

  return true;
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
