// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"

namespace flow {

ClipRectLayer::ClipRectLayer(ClipMode clip_mode) : clip_mode_(clip_mode) {}

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

  scenic::Rectangle shape(context.session(),   // session
                              clip_rect_.width(),  //  width
                              clip_rect_.height()  //  height
  );

  // TODO(liyuqian): respect clip_mode_
  SceneUpdateContext::Clip clip(context, shape, clip_rect_);
  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void ClipRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRectLayer::Paint");
  FXL_DCHECK(needs_painting());

  SkAutoCanvasRestore save(&context.canvas, clip_mode_ != ClipMode::hardEdge);
  context.canvas.clipRect(paint_bounds());
  if (clip_mode_ == ClipMode::antiAliasWithSaveLayer) {
    context.canvas.saveLayer(paint_bounds(), nullptr);
  }
  PaintChildren(context);
  if (clip_mode_ == ClipMode::antiAliasWithSaveLayer) {
    context.canvas.restore();
  }
}

}  // namespace flow
