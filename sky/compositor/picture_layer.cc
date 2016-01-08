// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/picture_layer.h"

#include "base/logging.h"
#include "sky/compositor/checkerboard.h"
#include "sky/compositor/raster_cache.h"

#define ENABLE_RASTER_CACHE 0

namespace sky {
namespace compositor {

// TODO(abarth): Make this configurable by developers.
const bool kDebugCheckerboardRasterizedLayers = false;

PictureLayer::PictureLayer() {
}

PictureLayer::~PictureLayer() {
}

void PictureLayer::Preroll(PaintContext::ScopedFrame& frame,
                           const SkMatrix& matrix) {
#if ENABLE_RASTER_CACHE
  image_ = frame.context().raster_cache().GetImage(picture_.get(), matrix);
  if (image_) {
    image_->preroll(frame.gr_context(), SkShader::kClamp_TileMode,
                    SkShader::kClamp_TileMode, kMedium_SkFilterQuality);
  }
#endif
}

void PictureLayer::Paint(PaintContext::ScopedFrame& frame) {
  DCHECK(picture_);

  SkCanvas& canvas = frame.canvas();
  if (image_) {
    const SkMatrix& ctm = canvas.getTotalMatrix();
    SkScalar scaleX = ctm.getScaleX();
    SkScalar scaleY = ctm.getScaleY();

    SkRect rect = picture_->cullRect();
    SkScalar dx = (offset_.x() + rect.left()) * scaleX;
    SkScalar dy = (offset_.y() + rect.top()) * scaleY;

    canvas.save();
    canvas.scale(1.0 / scaleX, 1.0 / scaleY);
    canvas.drawImage(image_.get(), dx, dy);
    canvas.restore();

    if (kDebugCheckerboardRasterizedLayers) {
      SkRect rect = paint_bounds().makeOffset(offset_.x(), offset_.y());
      DrawCheckerboard(&canvas, rect);
    }
  } else {
    canvas.save();
    canvas.translate(offset_.x(), offset_.y());
    canvas.drawPicture(picture_.get());
    canvas.restore();
  }
}

}  // namespace compositor
}  // namespace sky
