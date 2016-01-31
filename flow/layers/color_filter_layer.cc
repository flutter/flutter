// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/color_filter_layer.h"

namespace flow {

ColorFilterLayer::ColorFilterLayer() {
}

ColorFilterLayer::~ColorFilterLayer() {
}

void ColorFilterLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  ContainerLayer::Preroll(context, matrix);
  set_paint_bounds(context->child_paint_bounds);
}

void ColorFilterLayer::Paint(PaintContext::ScopedFrame& frame) {
  skia::RefPtr<SkColorFilter> color_filter =
      skia::AdoptRef(SkColorFilter::CreateModeFilter(color_, transfer_mode_));
  SkPaint paint;
  paint.setColorFilter(color_filter.get());

  SkCanvas& canvas = frame.canvas();
  SkAutoCanvasRestore save(&canvas, false);
  canvas.saveLayer(&paint_bounds(), &paint);
  PaintChildren(frame);
}

}  // namespace flow
