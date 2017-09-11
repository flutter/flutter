// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"

namespace flow {

ClipRectLayer::ClipRectLayer() = default;

ClipRectLayer::~ClipRectLayer() = default;

void ClipRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);

  if (child_paint_bounds.intersect(clip_rect_)) {
    set_paint_bounds(child_paint_bounds);
  }
}

#if defined(OS_FUCHSIA)

void ClipRectLayer::UpdateScene(SceneUpdateContext& context) {
  FXL_DCHECK(needs_system_composite());

  scenic_lib::Rectangle shape(context.session(),   // session
                                  clip_rect_.width(),  //  width
                                  clip_rect_.height()  //  height
                                  );

  SceneUpdateContext::Clip clip(context, shape, clip_rect_);
  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void ClipRectLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ClipRectLayer::Paint");
  FXL_DCHECK(needs_painting());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.clipRect(paint_bounds());
  PaintChildren(context);
}

}  // namespace flow
