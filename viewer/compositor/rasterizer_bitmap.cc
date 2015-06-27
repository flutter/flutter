// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/compositor/rasterizer_bitmap.h"

#include "sky/viewer/compositor/layer_client.h"
#include "sky/viewer/compositor/layer_host.h"
#include "third_party/skia/include/core/SkBitmapDevice.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gfx/codec/png_codec.h"
#include "ui/gfx/geometry/rect.h"

namespace sky {

RasterizerBitmap::RasterizerBitmap(LayerHost* host) : host_(host) {
  DCHECK(host_);
}

RasterizerBitmap::~RasterizerBitmap() {
}

void RasterizerBitmap::GetPixelsForTesting(std::vector<unsigned char>* pixels) {
  gfx::PNGCodec::EncodeBGRASkBitmap(bitmap_, true, pixels);
}

scoped_ptr<mojo::GLTexture> RasterizerBitmap::Rasterize(SkPicture* picture) {
  auto size = picture->cullRect();
  bitmap_.allocN32Pixels(size.width(), size.height());

  SkBitmapDevice device(bitmap_);
  SkCanvas canvas(&device);
  // Draw red so we can see when we fail to paint.
  canvas.drawColor(SK_ColorRED);
  canvas.drawPicture(picture);
  canvas.flush();

  return host_->resource_manager()->CreateTexture(
      gfx::Size(size.width(), size.height()));
}

}  // namespace sky
