// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

namespace flutter {

ClipRRectLayer::ClipRRectLayer(const SkRRect& clip_rrect, Clip clip_behavior)
    : clip_rrect_(clip_rrect), clip_behavior_(clip_behavior) {
  FML_DCHECK(clip_behavior != Clip::none);
}

ClipRRectLayer::~ClipRRectLayer() = default;

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkRect previous_cull_rect = context->cull_rect;
  SkRect clip_rrect_bounds = clip_rrect_.getBounds();
  if (context->cull_rect.intersect(clip_rrect_bounds)) {
    context->mutators_stack.PushClipRRect(clip_rrect_);
    SkRect child_paint_bounds = SkRect::MakeEmpty();
    PrerollChildren(context, matrix, &child_paint_bounds);

    if (child_paint_bounds.intersect(clip_rrect_bounds)) {
      set_paint_bounds(child_paint_bounds);
    }
    context->mutators_stack.Pop();
  }
  context->cull_rect = previous_cull_rect;
}

#if defined(OS_FUCHSIA)

void ClipRRectLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());

  // TODO(liyuqian): respect clip_behavior_
  SceneUpdateContext::Clip clip(context, clip_rrect_.getBounds());
  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void ClipRRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  FML_DCHECK(needs_painting());

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->clipRRect(clip_rrect_,
                                           clip_behavior_ != Clip::hardEdge);

  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    context.internal_nodes_canvas->saveLayer(paint_bounds(), nullptr);
  }
  PaintChildren(context);
  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    context.internal_nodes_canvas->restore();
  }
}

}  // namespace flutter
