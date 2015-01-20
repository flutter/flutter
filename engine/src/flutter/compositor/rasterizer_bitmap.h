// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_DISPLAY_RASTERIZER_BITMAP_H_
#define SKY_COMPOSITOR_DISPLAY_RASTERIZER_BITMAP_H_

#include "sky/compositor/rasterizer.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace sky {
class LayerHost;

class RasterizerBitmap : public Rasterizer {
 public:
  explicit RasterizerBitmap(LayerHost* host);
  ~RasterizerBitmap() override;

  scoped_ptr<mojo::GLTexture> Rasterize(SkPicture* picture) override;
  void GetPixelsForTesting(std::vector<unsigned char>* pixels);

 private:
  LayerHost* host_;
  SkBitmap bitmap_;

  DISALLOW_COPY_AND_ASSIGN(RasterizerBitmap);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_DISPLAY_RASTERIZER_BITMAP_H_
