// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/flow/layers/layer.h"
#include "flutter/glue/trace_event.h"

namespace flow {

LayerTree::LayerTree()
    : frame_size_{},
      scene_version_(0),
      rasterizer_tracing_threshold_(0),
      checkerboard_raster_cache_images_(false) {}

LayerTree::~LayerTree() {}

void LayerTree::Raster(CompositorContext::ScopedFrame& frame,
                       bool ignore_raster_cache) {
  Preroll(frame, ignore_raster_cache);
  Paint(frame);
}

void LayerTree::Preroll(CompositorContext::ScopedFrame& frame,
                        bool ignore_raster_cache) {
  TRACE_EVENT0("flutter", "LayerTree::Preroll");
  frame.context().raster_cache().SetCheckboardCacheImages(
      checkerboard_raster_cache_images_);
  Layer::PrerollContext context = {
      ignore_raster_cache ? nullptr : &frame.context().raster_cache(),
      frame.gr_context(), SkRect::MakeEmpty(),
  };
  root_layer_->Preroll(&context, SkMatrix::I());
}

#if defined(OS_FUCHSIA)
void LayerTree::UpdateScene(SceneUpdateContext& context,
                            mozart::Node* container) {
  TRACE_EVENT0("flutter", "LayerTree::UpdateScene");

  if (root_layer_->needs_system_composite()) {
    root_layer_->UpdateScene(context, container);
  } else {
    context.AddLayerToCurrentPaintTask(root_layer_.get());
  }
  context.FinalizeCurrentPaintTaskIfNeeded(container, SkMatrix::I());
}
#endif

void LayerTree::Paint(CompositorContext::ScopedFrame& frame) {
  Layer::PaintContext context = {frame.canvas(), frame.context().frame_time(),
                                 frame.context().engine_time(),
                                 frame.context().memory_usage()};
  TRACE_EVENT0("flutter", "LayerTree::Paint");
  root_layer_->Paint(context);
}

}  // namespace flow
