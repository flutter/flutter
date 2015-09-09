// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/picture_layer.h"
#include "base/logging.h"

namespace sky {
namespace compositor {

PictureLayer::PictureLayer() {
}

PictureLayer::~PictureLayer() {
}

SkMatrix PictureLayer::model_view_matrix(const SkMatrix& model_matrix) const {
  SkMatrix modelView = model_matrix;
  modelView.postTranslate(offset_.x(), offset_.y());
  return modelView;
}

void PictureLayer::Paint(PaintContext& context) {
  DCHECK(picture_);

  const SkRect& bounds = paint_bounds();
  SkISize size = SkISize::Make(bounds.width(), bounds.height());

  RefPtr<SkImage> image = context.rasterizer().GetCachedImageIfPresent(
      context.gr_context(), picture_.get(), size);
  SkCanvas* canvas = context.canvas();

  if (image) {
    canvas->drawImage(image.get(), offset_.x(), offset_.y());
  } else {
    canvas->save();
    canvas->translate(offset_.x(), offset_.y());
    canvas->drawPicture(picture_.get());
    canvas->restore();
  }
}

}  // namespace compositor
}  // namespace sky
