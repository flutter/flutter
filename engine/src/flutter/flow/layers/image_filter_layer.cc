// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/image_filter_layer.h"

namespace flutter {

ImageFilterLayer::ImageFilterLayer(sk_sp<SkImageFilter> filter)
    : filter_(std::move(filter)) {}

void ImageFilterLayer::Preroll(PrerollContext* context,
                               const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ImageFilterLayer::Preroll");

  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);

  child_paint_bounds_ = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds_);
  if (filter_) {
    const SkIRect filter_input_bounds = child_paint_bounds_.roundOut();
    SkIRect filter_output_bounds =
        filter_->filterBounds(filter_input_bounds, SkMatrix::I(),
                              SkImageFilter::kForward_MapDirection);
    set_paint_bounds(SkRect::Make(filter_output_bounds));
  } else {
    set_paint_bounds(child_paint_bounds_);
  }

  if (!context->has_platform_view && context->raster_cache &&
      SkRect::Intersects(context->cull_rect, paint_bounds())) {
    SkMatrix ctm = matrix;
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
    context->raster_cache->Prepare(context, this, ctm);
  }
}

void ImageFilterLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ImageFilterLayer::Paint");
  FML_DCHECK(needs_painting());

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  SkAutoCanvasRestore save(context.leaf_nodes_canvas, true);
  context.leaf_nodes_canvas->setMatrix(RasterCache::GetIntegralTransCTM(
      context.leaf_nodes_canvas->getTotalMatrix()));
#endif

  if (context.raster_cache &&
      context.raster_cache->Draw(this, *context.leaf_nodes_canvas)) {
    return;
  }

  SkPaint paint;
  paint.setImageFilter(filter_);

  // Normally a save_layer is sized to the current layer bounds, but in this
  // case the bounds of the child may not be the same as the filtered version
  // so we use the child_paint_bounds_ which were snapshotted from the
  // Preroll on the children before we adjusted them based on the filter.
  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, child_paint_bounds_, &paint);
  PaintChildren(context);
}

}  // namespace flutter
