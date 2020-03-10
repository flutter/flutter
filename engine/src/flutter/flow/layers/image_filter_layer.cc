// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/image_filter_layer.h"

namespace flutter {

ImageFilterLayer::ImageFilterLayer(sk_sp<SkImageFilter> filter)
    : filter_(std::move(filter)) {}

void ImageFilterLayer::Preroll(PrerollContext* context,
                               const SkMatrix& matrix) {
  Layer::AutoPrerollSaveLayerState save =
      Layer::AutoPrerollSaveLayerState::Create(context);
  ContainerLayer::Preroll(context, matrix);

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

  if (context.raster_cache) {
    const SkMatrix& ctm = context.leaf_nodes_canvas->getTotalMatrix();
    RasterCacheResult layer_cache =
        context.raster_cache->Get((Layer*)this, ctm);
    if (layer_cache.is_valid()) {
      layer_cache.draw(*context.leaf_nodes_canvas);
      return;
    }
  }

  SkPaint paint;
  paint.setImageFilter(filter_);

  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flutter
