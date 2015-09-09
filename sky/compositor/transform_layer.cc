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

SkMatrix TransformLayer::model_view_matrix(const SkMatrix& model_matrix) const {
  SkMatrix modelView = model_matrix;
  modelView.postConcat(transform_);
  return modelView;
}

void TransformLayer::Paint(PaintContext& context) {
  SkCanvas* canvas = context.canvas();
  canvas->save();
  canvas->concat(transform_);
  PaintChildren(context);
  canvas->restore();
}

}  // namespace compositor
}  // namespace sky
