// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/texture.h"
#include "impeller/base/validation.h"

namespace impeller {

Texture::Texture(TextureDescriptor desc) : desc_(std::move(desc)) {}

Texture::~Texture() = default;

bool Texture::SetContents(const uint8_t* contents,
                          size_t length,
                          size_t slice) {
  switch (desc_.type) {
    case TextureType::kTexture2D:
    case TextureType::kTexture2DMultisample:
      if (slice != 0) {
        VALIDATION_LOG
            << "Slice must be 0 when setting the contents of a Texture2D.";
        return false;
      }
      break;
    case TextureType::kTextureCube:
      if (slice > 5) {
        VALIDATION_LOG << "Slice must be <= 5 when setting the contents of a "
                          "cube texture.";
        return false;
      }
      break;
  }

  return OnSetContents(contents, length, slice);
}

const TextureDescriptor& Texture::GetTextureDescriptor() const {
  return desc_;
}

}  // namespace impeller
