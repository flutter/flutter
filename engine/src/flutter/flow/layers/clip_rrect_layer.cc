// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

namespace flutter {

ClipRRectLayer::ClipRRectLayer(const SkRRect& clip_rrect, Clip clip_behavior)
    : ClipShapeLayer(clip_rrect, clip_behavior) {}

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Preroll");
  ClipShapeLayer::Preroll(context, matrix);
}

void ClipRRectLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  ClipShapeLayer::Paint(context);
}

const SkRect& ClipRRectLayer::clip_shape_bounds() const {
  return clip_shape().getBounds();
}

void ClipRRectLayer::OnMutatorsStackPushClipShape(
    MutatorsStack& mutators_stack) {
  mutators_stack.PushClipRRect(clip_shape());
}

void ClipRRectLayer::OnCanvasClipShape(SkCanvas* canvas) const {
  canvas->clipRRect(clip_shape(), clip_behavior() != Clip::hardEdge);
}

}  // namespace flutter
