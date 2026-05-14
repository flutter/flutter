// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

namespace flutter {

ClipPathLayer::ClipPathLayer(const DlPath& clip_path, Clip clip_behavior)
    : ClipShapeLayer(clip_path, clip_behavior) {}

const DlRect ClipPathLayer::clip_shape_bounds() const {
  return clip_shape().GetBounds();
}

void ClipPathLayer::ApplyClip(LayerStateStack::MutatorContext& mutator) const {
  bool is_aa = clip_behavior() != Clip::kHardEdge;
  DlRect rect;
  if (clip_shape().IsRect(&rect)) {
    mutator.clipRect(rect, is_aa);
  } else if (clip_shape().IsOval(&rect)) {
    mutator.clipRRect(DlRoundRect::MakeOval(rect), is_aa);
  } else {
    DlRoundRect rrect;
    if (clip_shape().IsRoundRect(&rrect)) {
      mutator.clipRRect(rrect, is_aa);
    } else {
      clip_shape().WillRenderSkPath();
      mutator.clipPath(clip_shape(), is_aa);
    }
  }
}

void ClipPathLayer::PushClipToEmbeddedNativeViewMutatorStack(
    ExternalViewEmbedder* view_embedder) const {
  view_embedder->PushClipPathToVisitedPlatformViews(clip_shape());
}

}  // namespace flutter
