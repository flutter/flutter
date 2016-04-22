// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/container_layer.h"

namespace flow {

ContainerLayer::ContainerLayer() {
}

ContainerLayer::~ContainerLayer() {
}

void ContainerLayer::Add(std::unique_ptr<Layer> layer) {
  layer->set_parent(this);
  layers_.push_back(std::move(layer));
}

void ContainerLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  PrerollChildren(context, matrix);
  set_paint_bounds(context->child_paint_bounds);
}

void ContainerLayer::PrerollChildren(PrerollContext* context,
                                     const SkMatrix& matrix) {
  SkRect child_paint_bounds;
  for (auto& layer : layers_) {
    PrerollContext child_context = *context;
    layer->Preroll(&child_context, matrix);
    child_paint_bounds.join(child_context.child_paint_bounds);
  }
  context->child_paint_bounds = child_paint_bounds;
}

void ContainerLayer::PaintChildren(PaintContext& context) const {
  for (auto& layer : layers_)
    layer->Paint(context);
}

void ContainerLayer::UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                                 mojo::gfx::composition::Node* container) {
  for (auto& layer : layers_)
    layer->UpdateScene(update, container);
}

}  // namespace flow
