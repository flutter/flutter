// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

namespace flow {

OpacityLayer::OpacityLayer() = default;

OpacityLayer::~OpacityLayer() = default;

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  ContainerLayer::Preroll(context, matrix);
  if (context->raster_cache && layers().size() == 1) {
    std::shared_ptr<Layer> child = layers()[0];
    SkMatrix ctm = matrix;
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
    context->raster_cache->Prepare(context, child, ctm);
  }
}

void OpacityLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FML_DCHECK(needs_painting());

  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(&context.canvas, true);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.canvas.setMatrix(
      RasterCache::GetIntegralTransCTM(context.canvas.getTotalMatrix()));
#endif

  if (layers().size() == 1 && context.raster_cache) {
    const SkMatrix& ctm = context.canvas.getTotalMatrix();
    RasterCacheResult child_cache = context.raster_cache->Get(layers()[0], ctm);
    if (child_cache.is_valid()) {
      child_cache.draw(context.canvas, &paint);
      return;
    }
  }

  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
