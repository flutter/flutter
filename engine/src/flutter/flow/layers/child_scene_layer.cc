// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

#include "flutter/flow/export_node.h"
#include "flutter/flow/view_holder.h"

namespace flow {

ChildSceneLayer::ChildSceneLayer(zx_koid_t layer_id,
                                 bool use_view_holder,
                                 const SkPoint& offset,
                                 const SkSize& size,
                                 bool hit_testable)
    : layer_id_(layer_id),
      offset_(offset),
      size_(size),
      hit_testable_(hit_testable),
      use_view_holder_(use_view_holder) {}

void ChildSceneLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  set_needs_system_composite(true);
}

void ChildSceneLayer::Paint(PaintContext& context) const {
  FML_NOTREACHED() << "This layer never needs painting.";
}

void ChildSceneLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());

  if (use_view_holder_) {
    auto* view_holder = ViewHolder::FromId(layer_id_);
    FML_DCHECK(view_holder);

    view_holder->UpdateScene(context, offset_, size_, hit_testable_);
  } else {
    auto* export_node = ExportNode::FromId(layer_id_);
    FML_DCHECK(export_node);

    export_node->UpdateScene(context, offset_, size_, hit_testable_);
  }
}

}  // namespace flow
