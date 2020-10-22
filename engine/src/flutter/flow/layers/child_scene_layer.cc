// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

namespace flutter {

ChildSceneLayer::ChildSceneLayer(zx_koid_t layer_id,
                                 const SkPoint& offset,
                                 const SkSize& size,
                                 bool hit_testable)
    : layer_id_(layer_id),
      offset_(offset),
      size_(size),
      hit_testable_(hit_testable) {}

void ChildSceneLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ChildSceneLayer::Preroll");

  context->child_scene_layer_exists_below = true;
  CheckForChildLayerBelow(context);
}

void ChildSceneLayer::Paint(PaintContext& context) const {}

void ChildSceneLayer::UpdateScene(std::shared_ptr<SceneUpdateContext> context) {
  TRACE_EVENT0("flutter", "ChildSceneLayer::UpdateScene");
  FML_DCHECK(needs_system_composite());
  context->UpdateView(layer_id_, offset_, size_, hit_testable_);
}

}  // namespace flutter
