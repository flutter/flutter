// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

namespace flow {

ClipPathLayer::ClipPathLayer() {}

ClipPathLayer::~ClipPathLayer() {}

void ClipPathLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);
  if (!context->child_paint_bounds.intersect(clip_path_.getBounds()))
    context->child_paint_bounds.setEmpty();
  set_paint_bounds(context->child_paint_bounds);
}

void ClipPathLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ClipPathLayer::Paint");
  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(&paint_bounds(), nullptr);
  context.canvas.clipPath(clip_path_, true);
  PaintChildren(context);
}

}  // namespace flow
