// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/clip_rect_layer.h"

namespace flow {

ClipRectLayer::ClipRectLayer() {
}

ClipRectLayer::~ClipRectLayer() {
}

void ClipRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);
  if (!context->child_paint_bounds.intersect(clip_rect_))
    context->child_paint_bounds.setEmpty();
  set_paint_bounds(context->child_paint_bounds);
}

void ClipRectLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ClipRectLayer::Paint");
  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.clipRect(paint_bounds());
  PaintChildren(context);
}

}  // namespace flow
