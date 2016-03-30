// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/layers/layer_tree.h"

#include "base/trace_event/trace_event.h"
#include "flow/layers/layer.h"

namespace flow {

LayerTree::LayerTree() : scene_version_(0), rasterizer_tracing_threashold_(0) {
}

LayerTree::~LayerTree() {
}

void LayerTree::Raster(PaintContext::ScopedFrame& frame) {
  {
    TRACE_EVENT0("flutter", "LayerTree::Preroll");
    Layer::PrerollContext context = { frame, SkRect::MakeEmpty() };
    root_layer_->Preroll(&context, SkMatrix());
  }

  {
    TRACE_EVENT0("flutter", "LayerTree::Paint");
    root_layer_->Paint(frame);
  }
}

void LayerTree::UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                            mojo::gfx::composition::Node* container) {
  TRACE_EVENT0("flutter", "LayerTree::UpdateScene");
  root_layer_->UpdateScene(update, container);
}

}  // namespace flow
