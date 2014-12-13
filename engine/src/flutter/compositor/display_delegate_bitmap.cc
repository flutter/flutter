// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/display_delegate_bitmap.h"

#include "sky/compositor/layer_client.h"
#include "third_party/skia/include/core/SkBitmapDevice.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "ui/gfx/codec/png_codec.h"
#include "ui/gfx/geometry/rect.h"

namespace sky {

DisplayDelegateBitmap::DisplayDelegateBitmap(LayerClient* client)
  : client_(client) {}

DisplayDelegateBitmap::~DisplayDelegateBitmap() {}

DisplayDelegate* DisplayDelegateBitmap::create(LayerClient* client) {
  return new DisplayDelegateBitmap(client);
}

void DisplayDelegateBitmap::GetPixelsForTesting(std::vector<unsigned char>* pixels) {
  gfx::PNGCodec::EncodeBGRASkBitmap(bitmap_, false, pixels);
}

void DisplayDelegateBitmap::Paint(mojo::GaneshSurface& surface, const gfx::Rect& size) {
  bitmap_.allocN32Pixels(size.width(), size.height());
  SkBitmapDevice device(bitmap_);
  SkCanvas canvas(&device);
  // Draw red so we can see when we fail to paint.
  canvas.drawColor(SK_ColorRED);

  client_->PaintContents(&canvas, size);
  canvas.flush();
}

}  // namespace sky
