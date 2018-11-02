// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

namespace flow {

OpacityLayer::OpacityLayer() = default;

OpacityLayer::~OpacityLayer() = default;

void OpacityLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkMatrix child_matrix = matrix;
  child_matrix.postTranslate(offset_.fX, offset_.fY);
  ContainerLayer::Preroll(context, child_matrix);
  if (context->raster_cache && layers().size() == 1) {
    Layer* child = layers()[0].get();
    SkMatrix ctm = child_matrix;
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

  SkAutoCanvasRestore save(context.canvas, true);
  context.canvas->translate(offset_.fX, offset_.fY);

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.canvas->setMatrix(
      RasterCache::GetIntegralTransCTM(context.canvas->getTotalMatrix()));
#endif

  if (layers().size() == 1 && context.raster_cache) {
    const SkMatrix& ctm = context.canvas->getTotalMatrix();
    RasterCacheResult child_cache =
        context.raster_cache->Get(layers()[0].get(), ctm);
    if (child_cache.is_valid()) {
      child_cache.draw(*context.canvas, &paint);
      return;
    }
  }

  Layer::AutoSaveLayer save_layer =
      Layer::AutoSaveLayer::Create(context, paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
