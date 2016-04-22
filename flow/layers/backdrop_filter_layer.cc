// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/backdrop_filter_layer.h"

#include "third_party/skia/include/core/SkImageFilter.h"

namespace flow {

BackdropFilterLayer::BackdropFilterLayer() {
}

BackdropFilterLayer::~BackdropFilterLayer() {
}

void BackdropFilterLayer::Paint(PaintContext& context) {
  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(SkCanvas::SaveLayerRec{
      &paint_bounds(), nullptr, filter_.get(), 0});
  PaintChildren(context);
}

}  // namespace flow
