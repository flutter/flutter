// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/compositor/texture_cache.h"

#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/gpu/gl_texture.h"

namespace sky {

TextureCache::TextureCache() {
}

TextureCache::~TextureCache() {
}

scoped_ptr<mojo::GLTexture> TextureCache::GetTexture(const gfx::Size& size) {
  if (size != size_) {
    available_textures_.clear();
    size_ = size;
  }
  if (available_textures_.empty())
    return nullptr;
  scoped_ptr<mojo::GLTexture> texture(available_textures_.back());
  available_textures_.back() = nullptr;
  available_textures_.pop_back();
  return texture.Pass();
}

void TextureCache::PutTexture(scoped_ptr<mojo::GLTexture> texture) {
  if (texture->size() != size_)
    return;
  available_textures_.push_back(texture.release());
}

}  // namespace sky
