// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/opacity_layer.h"

namespace sky {
namespace compositor {

OpacityLayer::OpacityLayer() {
}

OpacityLayer::~OpacityLayer() {
}

void OpacityLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkPaint paint;
  paint.setColor(SkColorSetARGB(alpha_, 0, 0, 0));
  paint.setXfermodeMode(SkXfermode::kSrcOver_Mode);
  SkCanvas& canvas = frame.canvas();
  canvas.saveLayer(has_paint_bounds() ? &paint_bounds() : nullptr, &paint);
  PaintChildren(frame);
  canvas.restore();
}

}  // namespace compositor
}  // namespace sky
