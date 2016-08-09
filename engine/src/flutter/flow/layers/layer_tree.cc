// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/glue/trace_event.h"
#include "flutter/flow/layers/layer.h"

namespace flow {

LayerTree::LayerTree() : scene_version_(0), rasterizer_tracing_threshold_(0) {}

LayerTree::~LayerTree() {}

void LayerTree::Raster(CompositorContext::ScopedFrame& frame) {
  {
    TRACE_EVENT0("flutter", "LayerTree::Preroll");
    Layer::PrerollContext context = {
        frame.context().raster_cache(), frame.gr_context(), SkRect::MakeEmpty(),
    };
    root_layer_->Preroll(&context, SkMatrix());
  }

  {
    Layer::PaintContext context = {
        frame.canvas(), frame.context().frame_time(),
        frame.context().engine_time(),
    };
    TRACE_EVENT0("flutter", "LayerTree::Paint");
    root_layer_->Paint(context);
  }
}

void LayerTree::UpdateScene(mojo::gfx::composition::SceneUpdate* update,
                            mojo::gfx::composition::Node* container) {
  TRACE_EVENT0("flutter", "LayerTree::UpdateScene");
  root_layer_->UpdateScene(update, container);
}

}  // namespace flow
