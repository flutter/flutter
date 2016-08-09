// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

namespace flow {

OpacityLayer::OpacityLayer() {}

OpacityLayer::~OpacityLayer() {}

void OpacityLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(&paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
