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

void PictureLayer::Paint(PaintContext::ScopedFrame& frame) {
  DCHECK(picture_);

  SkCanvas& canvas = frame.canvas();
  canvas.save();
  canvas.translate(offset_.x(), offset_.y());
  canvas.drawPicture(picture_.get());
  canvas.restore();
}

}  // namespace compositor
}  // namespace sky
