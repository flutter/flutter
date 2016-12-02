// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/container_layer.h"

namespace flow {

ContainerLayer::ContainerLayer() {
  ctm_.setIdentity();
}

ContainerLayer::~ContainerLayer() {}

void ContainerLayer::Add(std::unique_ptr<Layer> layer) {
  layer->set_parent(this);
  layers_.push_back(std::move(layer));
}

void ContainerLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "ContainerLayer::Preroll");
  PrerollChildren(context, matrix);
  set_paint_bounds(context->child_paint_bounds);
}

void ContainerLayer::PrerollChildren(PrerollContext* context,
                                     const SkMatrix& matrix) {
  SkRect child_paint_bounds = SkRect::MakeEmpty();
  for (auto& layer : layers_) {
    PrerollContext child_context = *context;
    FTL_DCHECK(child_context.child_paint_bounds.isEmpty());
    layer->Preroll(&child_context, matrix);
    if (layer->needs_system_composite())
      set_needs_system_composite(true);
    child_paint_bounds.join(child_context.child_paint_bounds);
  }
  context->child_paint_bounds = child_paint_bounds;

  if (needs_system_composite())
    ctm_ = matrix;
}

void ContainerLayer::PaintChildren(PaintContext& context) const {
  FTL_DCHECK(!needs_system_composite());
  // Intentionally not tracing here as there should be no self-time
  // and the trace event on this common function has a small overhead.
  for (auto& layer : layers_)
    layer->Paint(context);
}

#if defined(OS_FUCHSIA)

void ContainerLayer::UpdateScene(SceneUpdateContext& context,
                                 mozart::Node* container) {
  UpdateSceneChildren(context, container);
}

void ContainerLayer::UpdateSceneChildrenInsideNode(SceneUpdateContext& context,
                                                   mozart::Node* container,
                                                   mozart::NodePtr node) {
  FTL_DCHECK(needs_system_composite());
  UpdateSceneChildren(context, node.get());
  context.FinalizeCurrentPaintTaskIfNeeded(node.get(), ctm());
  context.AddChildNode(container, std::move(node));
}

void ContainerLayer::UpdateSceneChildren(SceneUpdateContext& context,
                                         mozart::Node* container) {
  FTL_DCHECK(needs_system_composite());
  for (auto& layer : layers_) {
    if (layer->needs_system_composite()) {
      context.FinalizeCurrentPaintTaskIfNeeded(container, ctm());
      layer->UpdateScene(context, container);
    } else {
      context.AddLayerToCurrentPaintTask(layer.get());
    }
  }
}

#endif  // defined(OS_FUCHSIA)

}  // namespace flow
