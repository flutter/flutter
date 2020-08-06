// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/child_scene_layer.h"

#include "flutter/flow/view_holder.h"

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
  set_needs_system_composite(true);

  CheckForChildLayerBelow(context);

  context->child_scene_layer_exists_below = true;

  // An alpha "hole punch" is required if the frame behind us is not opaque.
  if (!context->is_opaque) {
    set_paint_bounds(
        SkRect::MakeXYWH(offset_.fX, offset_.fY, size_.fWidth, size_.fHeight));
  }
}

void ChildSceneLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ChildSceneLayer::Paint");
  FML_DCHECK(needs_painting());
  FML_DCHECK(needs_system_composite());

  // If we are being rendered into our own frame using the system compositor,
  // then it is neccesary to "punch a hole" in the canvas/frame behind us so
  // that group opacity looks correct.
  SkPaint paint;
  paint.setColor(SK_ColorTRANSPARENT);
  paint.setBlendMode(SkBlendMode::kSrc);
  context.leaf_nodes_canvas->drawRect(paint_bounds(), paint);
}

void ChildSceneLayer::UpdateScene(SceneUpdateContext& context) {
  TRACE_EVENT0("flutter", "ChildSceneLayer::UpdateScene");
  FML_DCHECK(needs_system_composite());

  Layer::UpdateScene(context);

  auto* view_holder = ViewHolder::FromId(layer_id_);
  FML_DCHECK(view_holder);

  view_holder->UpdateScene(context, offset_, size_,
                           SkScalarRoundToInt(context.alphaf() * 255),
                           hit_testable_);
}

}  // namespace flutter
