// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/picture_layer.h"

#include "base/logging.h"
#include "sky/compositor/checkerboard.h"
#include "sky/compositor/raster_cache.h"

namespace sky {
namespace compositor {

// TODO(abarth): Make this configurable by developers.
const bool kDebugCheckerboardRasterizedLayers = false;

PictureLayer::PictureLayer() {
}

PictureLayer::~PictureLayer() {
}

void PictureLayer::Preroll(PrerollContext* context,
                           const SkMatrix& matrix) {
  image_ = context->frame.context().raster_cache().GetPrerolledImage(
      context->frame.gr_context(), picture_.get(), matrix);
  context->child_paint_bounds = picture_->cullRect().makeOffset(offset_.x(), offset_.y());
}

void PictureLayer::Paint(PaintContext::ScopedFrame& frame) {
  DCHECK(picture_);

  SkCanvas& canvas = frame.canvas();
  if (image_) {
    SkRect rect = picture_->cullRect().makeOffset(offset_.x(), offset_.y());
    canvas.drawImageRect(image_.get(), rect, nullptr, SkCanvas::kFast_SrcRectConstraint);
    if (kDebugCheckerboardRasterizedLayers)
      DrawCheckerboard(&canvas, rect);
  } else {
    SkAutoCanvasRestore save(&canvas, true);
    canvas.translate(offset_.x(), offset_.y());
    canvas.drawPicture(picture_.get());
  }
}

}  // namespace compositor
}  // namespace sky
