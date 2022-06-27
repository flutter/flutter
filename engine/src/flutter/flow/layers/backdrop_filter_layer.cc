// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/backdrop_filter_layer.h"

namespace flutter {

BackdropFilterLayer::BackdropFilterLayer(sk_sp<SkImageFilter> filter,
                                         SkBlendMode blend_mode)
    : filter_(std::move(filter)), blend_mode_(blend_mode) {}

void BackdropFilterLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  auto* prev = static_cast<const BackdropFilterLayer*>(old_layer);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(prev);
    if (filter_ != prev->filter_) {
      context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(old_layer));
    }
  }

  // Backdrop filter paints everywhere in cull rect
  auto paint_bounds = context->GetCullRect();
  context->AddLayerBounds(paint_bounds);

  if (filter_) {
    context->GetTransform().mapRect(&paint_bounds);
    auto input_filter_bounds = paint_bounds.roundOut();
    auto filter_bounds =  // in screen coordinates
        filter_->filterBounds(input_filter_bounds, context->GetTransform(),
                              SkImageFilter::kReverse_MapDirection);
    context->AddReadbackRegion(filter_bounds);
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
}

void BackdropFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "BackdropFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  SkPaint paint;
  paint.setBlendMode(blend_mode_);
  Layer::AutoSaveLayer save = Layer::AutoSaveLayer::Create(
      context,
      SkCanvas::SaveLayerRec{&paint_bounds(), &paint, filter_.get(), 0},
      // BackdropFilter should only happen on the leaf nodes canvas.
      // See https:://flutter.dev/go/backdrop-filter-with-overlay-canvas
      AutoSaveLayer::SaveMode::kLeafNodesCanvas);
  PaintChildren(context);
}

}  // namespace flutter
