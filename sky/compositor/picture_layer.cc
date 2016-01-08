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
  SkISize size = SkISize::Make(paint_bounds().width() * matrix.getScaleX(),
                               paint_bounds().height() * matrix.getScaleY());

  RasterCache& cache = frame.context().raster_cache();
  image_ = cache.GetImage(picture_.get(), size);
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
    canvas.drawImage(image_.get(), offset_.x(), offset_.y());
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
