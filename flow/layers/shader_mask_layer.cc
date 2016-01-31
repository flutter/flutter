// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/shader_mask_layer.h"

namespace flow {

ShaderMaskLayer::ShaderMaskLayer() {
}

ShaderMaskLayer::~ShaderMaskLayer() {
}

void ShaderMaskLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  ContainerLayer::Preroll(context, matrix);
  set_paint_bounds(context->child_paint_bounds);
}

void ShaderMaskLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkCanvas& canvas = frame.canvas();
  SkAutoCanvasRestore save(&canvas, false);
  canvas.saveLayer(&paint_bounds(), nullptr);
  PaintChildren(frame);

  SkPaint paint;
  paint.setXfermodeMode(transfer_mode_);
  paint.setShader(shader_.get());
  canvas.translate(mask_rect_.left(), mask_rect_.top());
  canvas.drawRect(SkRect::MakeWH(mask_rect_.width(), mask_rect_.height()), paint);
}

}  // namespace flow
