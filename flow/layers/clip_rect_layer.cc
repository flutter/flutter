// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/paint_utils.h"

namespace flutter {

ClipRectLayer::ClipRectLayer(const SkRect& clip_rect, Clip clip_behavior)
    : clip_rect_(clip_rect), clip_behavior_(clip_behavior) {
  FML_DCHECK(clip_behavior != Clip::none);
}

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

void ClipRectLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const ClipRectLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (clip_behavior_ != prev->clip_behavior_ ||
        clip_rect_ != prev->clip_rect_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }
  if (context->PushCullRect(clip_rect_)) {
    DiffChildren(context, prev);
  }
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

void ClipRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ClipRectLayer::Preroll");

  SkRect previous_cull_rect = context->cull_rect;
  if (!context->cull_rect.intersect(clip_rect_)) {
    context->cull_rect.setEmpty();
  }
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, UsesSaveLayer());
  context->mutators_stack.PushClipRect(clip_rect_);

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);
  if (child_paint_bounds.intersect(clip_rect_)) {
    set_paint_bounds(child_paint_bounds);
  }

  context->mutators_stack.Pop();
  context->cull_rect = previous_cull_rect;
}

void ClipRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRectLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkAutoCanvasRestore save(context.internal_nodes_canvas, true);
  context.internal_nodes_canvas->clipRect(clip_rect_,
                                          clip_behavior_ != Clip::hardEdge);

  if (UsesSaveLayer()) {
    context.internal_nodes_canvas->saveLayer(clip_rect_, nullptr);
  }
  PaintChildren(context);
  if (UsesSaveLayer()) {
    context.internal_nodes_canvas->restore();
    if (context.checkerboard_offscreen_layers) {
      DrawCheckerboard(context.internal_nodes_canvas, clip_rect_);
    }
  }
}

}  // namespace flutter
