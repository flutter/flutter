// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/shader_layer.h"

namespace sky {
namespace compositor {

ShaderLayer::ShaderLayer() {
}

ShaderLayer::~ShaderLayer() {
}

void ShaderLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  ContainerLayer::Preroll(context, matrix);
  set_paint_bounds(context->child_paint_bounds);
}

void ShaderLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkPaint paint;
  paint.setXfermodeMode(transfer_mode_);
  paint.setShader(shader_.get());

  SkCanvas& canvas = frame.canvas();
  SkAutoCanvasRestore save(&canvas, false);
  canvas.saveLayer(&paint_bounds(), &paint);
  PaintChildren(frame);
}

}  // namespace compositor
}  // namespace sky
