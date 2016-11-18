// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/transform_layer.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/lib/skia/type_converters.h"
#include "apps/mozart/services/composition/nodes.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

TransformLayer::TransformLayer() {}

TransformLayer::~TransformLayer() {}

void TransformLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkMatrix childMatrix;
  childMatrix.setConcat(matrix, transform_);
  PrerollChildren(context, childMatrix);
  transform_.mapRect(&context->child_paint_bounds);
  set_paint_bounds(context->child_paint_bounds);
}

#if defined(OS_FUCHSIA)

void TransformLayer::UpdateScene(SceneUpdateContext& context,
                                 mozart::Node* container) {
  auto node = mozart::Node::New();
  node->content_transform = mozart::Transform::From(transform_);
  UpdateSceneChildrenInsideNode(context, container, std::move(node));
}

#endif  // defined(OS_FUCHSIA)

void TransformLayer::Paint(PaintContext& context) {
  TRACE_EVENT0("flutter", "TransformLayer::Paint");
  FTL_DCHECK(!needs_system_composite());

  SkAutoCanvasRestore save(&context.canvas, true);
  context.canvas.concat(transform_);
  PaintChildren(context);
}

}  // namespace flow
