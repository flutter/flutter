// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"
#include "flutter/flow/paint_utils.h"

namespace flutter {

ClipRRectLayer::ClipRRectLayer(const SkRRect& clip_rrect, Clip clip_behavior)
    : clip_rrect_(clip_rrect), clip_behavior_(clip_behavior) {
  FML_DCHECK(clip_behavior != Clip::none);
}

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Preroll");

  SkRect previous_cull_rect = context->cull_rect;
  SkRect clip_rrect_bounds = clip_rrect_.getBounds();
  context->cull_rect.intersect(clip_rrect_bounds);
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());
  context->mutators_stack.PushClipRRect(clip_rrect_);

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);
  if (child_paint_bounds.intersect(clip_rrect_bounds)) {
    set_paint_bounds(child_paint_bounds);
  }

  context->mutators_stack.Pop();
  context->cull_rect = previous_cull_rect;
}

#if defined(LEGACY_FUCHSIA_EMBEDDER)

void ClipRRectLayer::UpdateScene(std::shared_ptr<SceneUpdateContext> context) {
  TRACE_EVENT0("flutter", "ClipRRectLayer::UpdateScene");
  FML_DCHECK(needs_system_composite());

  // TODO(liyuqian): respect clip_behavior_
  SceneUpdateContext::Clip clip(context, clip_rrect_.getBounds());
  UpdateSceneChildren(context);
}

#endif

void ClipRRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->clipRRect(clip_rrect_,
                                           clip_behavior_ != Clip::hardEdge);

  if (UsesSaveLayer()) {
    context.internal_nodes_canvas->saveLayer(paint_bounds(), nullptr);
  }
  PaintChildren(context);
  if (UsesSaveLayer()) {
    context.internal_nodes_canvas->restore();
    if (context.checkerboard_offscreen_layers) {
      DrawCheckerboard(context.internal_nodes_canvas, paint_bounds());
    }
  }
}

}  // namespace flutter
