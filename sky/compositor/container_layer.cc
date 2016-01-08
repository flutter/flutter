// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/container_layer.h"

namespace sky {
namespace compositor {

ContainerLayer::ContainerLayer() {
}

ContainerLayer::~ContainerLayer() {
}

void ContainerLayer::Add(std::unique_ptr<Layer> layer) {
  layer->set_parent(this);
  layers_.push_back(std::move(layer));
}

void ContainerLayer::Preroll(PaintContext::ScopedFrame& frame,
                             const SkMatrix& matrix) {
  PrerollChildren(frame, matrix);
}

void ContainerLayer::PrerollChildren(PaintContext::ScopedFrame& frame,
                                     const SkMatrix& matrix) {
  for (auto& layer : layers_)
    layer->Preroll(frame, matrix);
}

void ContainerLayer::PaintChildren(PaintContext::ScopedFrame& frame) const {
  for (auto& layer : layers_)
    layer->Paint(frame);
}

}  // namespace compositor
}  // namespace sky
