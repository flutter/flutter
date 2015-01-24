// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_TEXTURE_CACHE_H_
#define SKY_COMPOSITOR_TEXTURE_CACHE_H_

#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "ui/gfx/geometry/size.h"

namespace mojo {
class GLTexture;
}

namespace sky {

class TextureCache {
 public:
  TextureCache();
  ~TextureCache();

  scoped_ptr<mojo::GLTexture> GetTexture(const gfx::Size& size);
  void PutTexture(scoped_ptr<mojo::GLTexture> texture);

 private:
  gfx::Size size_;
  ScopedVector<mojo::GLTexture> available_textures_;

  DISALLOW_COPY_AND_ASSIGN(TextureCache);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_TEXTURE_CACHE_H_
