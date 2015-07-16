// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_COMPOSITOR_RASTERIZER_H_
#define SKY_VIEWER_COMPOSITOR_RASTERIZER_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/gpu/gl_texture.h"

class SkPicture;

namespace sky {

class Rasterizer {
 public:
  Rasterizer();
  virtual ~Rasterizer();

  virtual scoped_ptr<mojo::GLTexture> Rasterize(SkPicture* picture) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace sky

#endif  // SKY_VIEWER_COMPOSITOR_RASTERIZER_H_
