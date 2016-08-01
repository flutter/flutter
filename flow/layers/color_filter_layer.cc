// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/color_filter_layer.h"

namespace flow {

ColorFilterLayer::ColorFilterLayer() {}

ColorFilterLayer::~ColorFilterLayer() {}

void ColorFilterLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ColorFilterLayer::Paint");
  sk_sp<SkColorFilter> color_filter =
      SkColorFilter::MakeModeFilter(color_, transfer_mode_);
  SkPaint paint;
  paint.setColorFilter(std::move(color_filter));

  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(&paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
