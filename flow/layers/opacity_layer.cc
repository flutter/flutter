// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

OpacityLayer::OpacityLayer() {}

OpacityLayer::~OpacityLayer() {}

#if defined(OS_FUCHSIA)

void OpacityLayer::UpdateScene(SceneUpdateContext& context,
                               mozart::Node* container) {
  auto node = mozart::Node::New();
  node->op = mozart::NodeOp::New();
  node->op->set_layer(mozart::LayerNodeOp::New());
  node->op->get_layer()->layer_rect = mozart::RectF::From(paint_bounds());
  node->op->get_layer()->blend->alpha = alpha_;
  UpdateSceneChildrenInsideNode(context, container, std::move(node));
}

#endif  // defined(OS_FUCHSIA)

void OpacityLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "OpacityLayer::Paint");
  FTL_DCHECK(!needs_system_composite());

  SkPaint paint;
  paint.setAlpha(alpha_);

  SkAutoCanvasRestore save(&context.canvas, false);
  context.canvas.saveLayer(&paint_bounds(), &paint);
  PaintChildren(context);
}

}  // namespace flow
