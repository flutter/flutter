// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/transform_layer.h"

namespace sky {
namespace compositor {

TransformLayer::TransformLayer() {
}

TransformLayer::~TransformLayer() {
}

void TransformLayer::Preroll(PaintContext::ScopedFrame& frame,
                             const SkMatrix& matrix) {
  SkMatrix childMatrix;
  childMatrix.setConcat(matrix, transform_);
  PrerollChildren(frame, childMatrix);
}

void TransformLayer::Paint(PaintContext::ScopedFrame& frame) {
  SkCanvas& canvas = frame.canvas();
  canvas.save();
  canvas.concat(transform_);
  PaintChildren(frame);
  canvas.restore();
}

}  // namespace compositor
}  // namespace sky
