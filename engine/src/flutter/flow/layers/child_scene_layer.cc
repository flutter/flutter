// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

namespace flow {

ChildSceneLayer::ChildSceneLayer() = default;

ChildSceneLayer::~ChildSceneLayer() = default;

void ChildSceneLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  set_needs_system_composite(true);
}

void ChildSceneLayer::Paint(PaintContext& context) const {
  FXL_NOTREACHED() << "This layer never needs painting.";
}

void ChildSceneLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());

  // TODO(MZ-191): Set clip.
  // It's worth asking whether all children should be clipped implicitly
  // or whether we should leave this up to the Flutter application to decide.
  // In some situations, it might be useful to allow children to draw
  // outside of their layout bounds.
  if (export_node_holder_) {
    context.AddChildScene(export_node_holder_->export_node(), offset_,
                          hit_testable_);
  }
}

}  // namespace flow
