// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

namespace flutter {

ClipRRectLayer::ClipRRectLayer(const SkRRect& clip_rrect, Clip clip_behavior)
    : ClipShapeLayer(clip_rrect, clip_behavior) {}

const SkRect& ClipRRectLayer::clip_shape_bounds() const {
  return clip_shape().getBounds();
}

void ClipRRectLayer::ApplyClip(LayerStateStack::MutatorContext& mutator) const {
  mutator.clipRRect(clip_shape(), clip_behavior() != Clip::kHardEdge);
}

}  // namespace flutter
