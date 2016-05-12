// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/transform_layer.h"

namespace flow {

TransformLayer::TransformLayer() {
}

TransformLayer::~TransformLayer() {
}

void TransformLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkMatrix childMatrix;
  childMatrix.setConcat(matrix, transform_);
  PrerollChildren(context, childMatrix);
  transform_.mapRect(&context->child_paint_bounds);
}

void TransformLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "TransformLayer::Paint");
  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.concat(transform_);
  PaintChildren(context);
}

}  // namespace flow
