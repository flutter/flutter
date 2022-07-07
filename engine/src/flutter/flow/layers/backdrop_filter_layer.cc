// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/backdrop_filter_layer.h"

namespace flutter {

BackdropFilterLayer::BackdropFilterLayer(
    std::shared_ptr<const DlImageFilter> filter,
    DlBlendMode blend_mode)
    : filter_(std::move(filter)), blend_mode_(blend_mode) {}

void BackdropFilterLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const BackdropFilterLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (NotEquals(filter_, prev->filter_)) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  // Backdrop filter paints everywhere in cull rect
  auto paint_bounds = context->GetCullRect();
  context->AddLayerBounds(paint_bounds);

  if (filter_) {
    context->GetTransform().mapRect(&paint_bounds);
    auto filter_target_bounds = paint_bounds.roundOut();
    SkIRect filter_input_bounds;  // in screen coordinates
    filter_->get_input_device_bounds(
        filter_target_bounds, context->GetTransform(), filter_input_bounds);
    context->AddReadbackRegion(filter_input_bounds);
  }

  DiffChildren(context, prev);

  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void BackdropFilterLayer::Preroll(PrerollContext* context,
                                  const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, true, bool(filter_));
  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);
  child_paint_bounds.join(context->cull_rect);
  set_paint_bounds(child_paint_bounds);
  context->subtree_can_inherit_opacity = true;
}

void BackdropFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "BackdropFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  AutoCachePaint save_paint(context);
  save_paint.setBlendMode(blend_mode_);
  if (context.leaf_nodes_builder) {
    context.leaf_nodes_builder->saveLayer(&paint_bounds(),
                                          save_paint.dl_paint(), filter_.get());

    PaintChildren(context);

    context.leaf_nodes_builder->restore();
  } else {
    auto sk_filter = filter_ ? filter_->skia_object() : nullptr;
    Layer::AutoSaveLayer save = Layer::AutoSaveLayer::Create(
        context,
        SkCanvas::SaveLayerRec{&paint_bounds(), save_paint.sk_paint(),
                               sk_filter.get(), 0},
        // BackdropFilter should only happen on the leaf nodes canvas.
        // See https:://flutter.dev/go/backdrop-filter-with-overlay-canvas
        AutoSaveLayer::SaveMode::kLeafNodesCanvas);

    PaintChildren(context);
  }
}

}  // namespace flutter
