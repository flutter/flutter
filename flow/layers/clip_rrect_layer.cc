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

void ClipRRectLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ClipRRectLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (clip_behavior_ != prev->clip_behavior_ ||
        clip_rrect_ != prev->clip_rrect_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }
  if (context->PushCullRect(clip_rrect_.getBounds())) {
    DiffChildren(context, prev);
  }
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Preroll");

  SkRect previous_cull_rect = context->cull_rect;
  SkRect clip_rrect_bounds = clip_rrect_.getBounds();
  if (!context->cull_rect.intersect(clip_rrect_bounds)) {
    context->cull_rect.setEmpty();
  }
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());
  context->mutators_stack.PushClipRRect(clip_rrect_);

  // Collect inheritance information on our children in Preroll so that
  // we can pass it along by default.
  context->subtree_can_inherit_opacity = true;

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);
  if (child_paint_bounds.intersect(clip_rrect_bounds)) {
    set_paint_bounds(child_paint_bounds);
  }

  // If we use a SaveLayer then we can accept opacity on behalf
  // of our children and apply it in the saveLayer.
  if (UsesSaveLayer()) {
    context->subtree_can_inherit_opacity = true;
  }

  context->mutators_stack.Pop();
  context->cull_rect = previous_cull_rect;
}

void ClipRRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->clipRRect(clip_rrect_,
                                           clip_behavior_ != Clip::hardEdge);

  if (!UsesSaveLayer()) {
    PaintChildren(context);
    return;
  }

  AutoCachePaint cache_paint(context);
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  context.internal_nodes_canvas->saveLayer(paint_bounds(), cache_paint.paint());

  PaintChildren(context);

  context.internal_nodes_canvas->restore();
  if (context.checkerboard_offscreen_layers) {
    DrawCheckerboard(context.internal_nodes_canvas, paint_bounds());
  }
}

}  // namespace flutter
