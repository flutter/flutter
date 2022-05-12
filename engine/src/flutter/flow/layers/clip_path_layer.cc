// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

namespace flutter {

ClipPathLayer::ClipPathLayer(const SkPath& clip_path, Clip clip_behavior)
    : ClipShapeLayer(clip_path, clip_behavior) {}

void ClipPathLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ClipPathLayer::Preroll");
  ClipShapeLayer::Preroll(context, matrix);
}

void ClipPathLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipPathLayer::Paint");
  ClipShapeLayer::Paint(context);
}

const SkRect& ClipPathLayer::clip_shape_bounds() const {
  return clip_shape().getBounds();
}

void ClipPathLayer::OnMutatorsStackPushClipShape(
    MutatorsStack& mutators_stack) {
  mutators_stack.PushClipPath(clip_shape());
}

void ClipPathLayer::OnCanvasClipShape(SkCanvas* canvas) const {
  canvas->clipPath(clip_shape(), clip_behavior() != Clip::hardEdge);
}

}  // namespace flutter
