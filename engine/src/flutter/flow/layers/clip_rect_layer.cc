// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

ClipRectLayer::ClipRectLayer() {}

ClipRectLayer::~ClipRectLayer() {}

void ClipRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);
  if (!context->child_paint_bounds.intersect(clip_rect_))
    context->child_paint_bounds.setEmpty();
  set_paint_bounds(context->child_paint_bounds);
}

#if defined(OS_FUCHSIA)

void ClipRectLayer::UpdateScene(SceneUpdateContext& context,
                                mozart::Node* container) {
  auto node = mozart::Node::New();
  node->content_clip = mozart::RectF::From(clip_rect_);
  UpdateSceneChildrenInsideNode(context, container, std::move(node));
}

#endif  // defined(OS_FUCHSIA)

void ClipRectLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ClipRectLayer::Paint");
  FTL_DCHECK(!needs_system_composite());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.clipRect(paint_bounds());
  PaintChildren(context);
}

}  // namespace flow
