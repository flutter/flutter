// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

namespace flutter {

ClipPathLayer::ClipPathLayer(const DlPath& clip_path, Clip clip_behavior)
    : ClipShapeLayer(clip_path, clip_behavior) {}

const SkRect& ClipPathLayer::clip_shape_bounds() const {
  return clip_shape().GetSkPath().getBounds();
}

void ClipPathLayer::ApplyClip(LayerStateStack::MutatorContext& mutator) const {
  clip_shape().WillRenderSkPath();
  mutator.clipPath(clip_shape().GetSkPath(),
                   clip_behavior() != Clip::kHardEdge);
}

}  // namespace flutter
