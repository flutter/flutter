// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

ClipRRectLayer::ClipRRectLayer() {}

ClipRRectLayer::~ClipRRectLayer() {}

void ClipRRectLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);
  if (!context->child_paint_bounds.intersect(clip_rrect_.getBounds()))
    context->child_paint_bounds.setEmpty();
  set_paint_bounds(context->child_paint_bounds);
}

#if defined(OS_FUCHSIA)

void ClipRRectLayer::UpdateScene(SceneUpdateContext& context,
                                 mozart::Node* container) {
  auto node = mozart::Node::New();
  node->content_clip = mozart::RectF::From(clip_rrect_.getBounds());
  UpdateSceneChildrenInsideNode(context, container, std::move(node));
}

#endif  // defined(OS_FUCHSIA)

void ClipRRectLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "ClipRRectLayer::Paint");
  FTL_DCHECK(!needs_system_composite());

  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(&paint_bounds(), nullptr);
  context.canvas.clipRRect(clip_rrect_, true);
  PaintChildren(context);
}

}  // namespace flow
