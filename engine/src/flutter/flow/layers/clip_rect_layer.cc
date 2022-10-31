// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"

namespace flutter {

ClipRectLayer::ClipRectLayer(const SkRect& clip_rect, Clip clip_behavior)
    : ClipShapeLayer(clip_rect, clip_behavior) {}

void ClipRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  ClipShapeLayer::Preroll(context, matrix);
}

void ClipRectLayer::Paint(PaintContext& context) const {
  ClipShapeLayer::Paint(context);
}

const SkRect& ClipRectLayer::clip_shape_bounds() const {
  return clip_shape();
}

void ClipRectLayer::OnMutatorsStackPushClipShape(
    MutatorsStack& mutators_stack) {
  mutators_stack.PushClipRect(clip_shape());
}

void ClipRectLayer::OnCanvasClipShape(SkCanvas* canvas) const {
  canvas->clipRect(clip_shape(), clip_behavior() != Clip::hardEdge);
}

}  // namespace flutter
