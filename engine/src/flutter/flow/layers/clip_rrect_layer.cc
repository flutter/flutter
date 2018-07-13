// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

namespace flow {

ClipRRectLayer::ClipRRectLayer(ClipMode clip_mode) : clip_mode_(clip_mode) {}

ClipRRectLayer::~ClipRRectLayer() = default;

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);

  if (child_paint_bounds.intersect(clip_rrect_.getBounds())) {
    set_paint_bounds(child_paint_bounds);
  }
}

#if defined(OS_FUCHSIA)

void ClipRRectLayer::UpdateScene(SceneUpdateContext& context) {
  FXL_DCHECK(needs_system_composite());

  // TODO(MZ-137): Need to be able to express the radii as vectors.
  scenic::RoundedRectangle shape(
      context.session(),                                   // session
      clip_rrect_.width(),                                 //  width
      clip_rrect_.height(),                                //  height
      clip_rrect_.radii(SkRRect::kUpperLeft_Corner).x(),   //  top_left_radius
      clip_rrect_.radii(SkRRect::kUpperRight_Corner).x(),  //  top_right_radius
      clip_rrect_.radii(SkRRect::kLowerRight_Corner)
          .x(),                                          //  bottom_right_radius
      clip_rrect_.radii(SkRRect::kLowerLeft_Corner).x()  //  bottom_left_radius
  );

  // TODO(liyuqian): respect clip_mode_
  SceneUpdateContext::Clip clip(context, shape, clip_rrect_.getBounds());
  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void ClipRRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  FXL_DCHECK(needs_painting());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.clipRRect(clip_rrect_, clip_mode_ != ClipMode::hardEdge);
  if (clip_mode_ == ClipMode::antiAliasWithSaveLayer) {
    context.canvas.saveLayer(paint_bounds(), nullptr);
  }
  PaintChildren(context);
  if (clip_mode_ == ClipMode::antiAliasWithSaveLayer) {
    context.canvas.restore();
  }
}

}  // namespace flow
