// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/picture_layer.h"

#include "flutter/fml/logging.h"

namespace flow {

PictureLayer::PictureLayer() = default;

PictureLayer::~PictureLayer() = default;

void PictureLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkPicture* sk_picture = picture();

  if (auto cache = context->raster_cache) {
    SkMatrix ctm = matrix;
    ctm.postTranslate(offset_.x(), offset_.y());
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    ctm = RasterCache::GetIntegralTransCTM(ctm);
#endif
    raster_cache_result_ = cache->GetPrerolledImage(
        context->gr_context, sk_picture, ctm, context->dst_color_space,
        is_complex_, will_change_);
  } else {
    raster_cache_result_ = RasterCacheResult();
  }

  SkRect bounds = sk_picture->cullRect().makeOffset(offset_.x(), offset_.y());
  set_paint_bounds(bounds);
}

void PictureLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "PictureLayer::Paint");
  FML_DCHECK(picture_.get());
  FML_DCHECK(needs_painting());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.translate(offset_.x(), offset_.y());
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  context.canvas.setMatrix(
      RasterCache::GetIntegralTransCTM(context.canvas.getTotalMatrix()));
#endif

  if (raster_cache_result_.is_valid()) {
    raster_cache_result_.draw(context.canvas,
                              context.root_surface_transformation);
  } else {
    context.canvas.drawPicture(picture());
  }
}

}  // namespace flow
