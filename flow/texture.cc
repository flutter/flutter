// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/texture.h"

namespace flow {

TextureRegistry::TextureRegistry() = default;

TextureRegistry::~TextureRegistry() = default;

void TextureRegistry::RegisterTexture(std::shared_ptr<Texture> texture) {
  ASSERT_IS_GPU_THREAD
  mapping_[texture->Id()] = texture;
}

void TextureRegistry::UnregisterTexture(int64_t id) {
  ASSERT_IS_GPU_THREAD
  mapping_.erase(id);
}

void TextureRegistry::OnGrContextCreated() {
  ASSERT_IS_GPU_THREAD;
  for (auto& it : mapping_) {
    it.second->OnGrContextCreated();
  }
}

void TextureRegistry::OnGrContextDestroyed() {
  ASSERT_IS_GPU_THREAD;
  for (auto& it : mapping_) {
    it.second->OnGrContextDestroyed();
  }
}

std::shared_ptr<Texture> TextureRegistry::GetTexture(int64_t id) {
  ASSERT_IS_GPU_THREAD
  return mapping_[id];
}

Texture::Texture(int64_t id) : id_(id) {}
Texture::~Texture() = default;

}  // namespace flow
