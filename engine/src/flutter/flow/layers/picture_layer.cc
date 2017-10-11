// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/picture_layer.h"

#include "flutter/common/threads.h"
#include "lib/fxl/logging.h"

namespace flow {

PictureLayer::PictureLayer() = default;

PictureLayer::~PictureLayer() {
  // The picture may contain references to textures that are associated
  // with the IO thread's context.
  SkPicture* picture = picture_.release();
  if (picture) {
    blink::Threads::IO()->PostTask([picture]() { picture->unref(); });
  }
}

void PictureLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  if (auto cache = context->raster_cache) {
    raster_cache_result_ = cache->GetPrerolledImage(
        context->gr_context, picture_.get(), matrix, context->dst_color_space,
        is_complex_, will_change_);
  }

  SkRect bounds = picture_->cullRect().makeOffset(offset_.x(), offset_.y());
  set_paint_bounds(bounds);
}

void PictureLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "PictureLayer::Paint");
  FXL_DCHECK(picture_);
  FXL_DCHECK(needs_painting());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.translate(offset_.x(), offset_.y());

  if (raster_cache_result_.is_valid()) {
    SkPaint paint;
    paint.setFilterQuality(kLow_SkFilterQuality);
    context.canvas.drawImageRect(
        raster_cache_result_.image(),             // image
        raster_cache_result_.source_rect(),       // source
        raster_cache_result_.destination_rect(),  // destination
        &paint,                                   // paint
        SkCanvas::kStrict_SrcRectConstraint       // source constraint
    );
  } else {
    context.canvas.drawPicture(picture_.get());
  }
}

}  // namespace flow
