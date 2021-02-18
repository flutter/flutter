// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/backdrop_filter_layer.h"

namespace flutter {

BackdropFilterLayer::BackdropFilterLayer(sk_sp<SkImageFilter> filter)
    : filter_(std::move(filter)) {}

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

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

  // convert paint bounds and filter to screen coordinates
  context->GetTransform().mapRect(&paint_bounds);
  auto input_filter_bounds = paint_bounds.roundOut();
  auto filter = filter_->makeWithLocalMatrix(context->GetTransform());

  auto filter_bounds =  // in screen coordinates
      filter->filterBounds(input_filter_bounds, SkMatrix::I(),
                           SkImageFilter::kReverse_MapDirection);

  context->AddReadbackRegion(filter_bounds);

  DiffChildren(context, prev);

  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

void BackdropFilterLayer::Preroll(PrerollContext* context,
                                  const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context, true, bool(filter_));
  ContainerLayer::Preroll(context, matrix);
}

void BackdropFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "BackdropFilterLayer::Paint");
  FML_DCHECK(needs_painting(context));

  Layer::AutoSaveLayer save = Layer::AutoSaveLayer::Create(
      context,
      SkCanvas::SaveLayerRec{&paint_bounds(), nullptr, filter_.get(), 0});
  PaintChildren(context);
}

}  // namespace flutter
