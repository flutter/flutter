// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/texture.h"

namespace impeller {

Texture::Texture(TextureDescriptor desc) : desc_(std::move(desc)) {}

Texture::~Texture() = default;

const TextureDescriptor& Texture::GetTextureDescriptor() const {
  return desc_;
}

}  // namespace impeller
