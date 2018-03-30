// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/flow/layers/layer.h"
#include "flutter/glue/trace_event.h"

namespace flow {

LayerTree::LayerTree()
    : frame_size_{},
      rasterizer_tracing_threshold_(0),
      checkerboard_raster_cache_images_(false),
      checkerboard_offscreen_layers_(false) {}

LayerTree::~LayerTree() = default;

void LayerTree::Raster(CompositorContext::ScopedFrame& frame,
#if defined(OS_FUCHSIA)
                       gfx::Metrics* metrics,
#endif
                       bool ignore_raster_cache) {
#if defined(OS_FUCHSIA)
  FXL_DCHECK(metrics);
#endif
  Preroll(frame,
#if defined(OS_FUCHSIA)
          metrics,
#endif
          ignore_raster_cache);
  Paint(frame);
}

void LayerTree::Preroll(CompositorContext::ScopedFrame& frame,
#if defined(OS_FUCHSIA)
                        gfx::Metrics* metrics,
#endif
                        bool ignore_raster_cache) {
#if defined(OS_FUCHSIA)
  FXL_DCHECK(metrics);
#endif
  TRACE_EVENT0("flutter", "LayerTree::Preroll");
  SkColorSpace* color_space =
      frame.canvas() ? frame.canvas()->imageInfo().colorSpace() : nullptr;
  frame.context().raster_cache().SetCheckboardCacheImages(
      checkerboard_raster_cache_images_);
  Layer::PrerollContext context = {
#if defined(OS_FUCHSIA)
    metrics,
#endif
    ignore_raster_cache ? nullptr : &frame.context().raster_cache(),
    frame.gr_context(),
    color_space,
    SkRect::MakeEmpty(),
  };

  root_layer_->Preroll(&context, SkMatrix::I());
}

#if defined(OS_FUCHSIA)
void LayerTree::UpdateScene(SceneUpdateContext& context,
                            scenic_lib::ContainerNode& container) {
  TRACE_EVENT0("flutter", "LayerTree::UpdateScene");

  SceneUpdateContext::Transform transform(context, 1.f / device_pixel_ratio_,
                                          1.f / device_pixel_ratio_, 1.f);
  SceneUpdateContext::Frame frame(
      context,
      SkRRect::MakeRect(
          SkRect::MakeWH(frame_size_.width(), frame_size_.height())),
      SK_ColorTRANSPARENT, 0.f);
  if (root_layer_->needs_system_composite()) {
    root_layer_->UpdateScene(context);
  }
  if (root_layer_->needs_painting()) {
    frame.AddPaintedLayer(root_layer_.get());
  }
  container.AddChild(transform.entity_node());
}
#endif

void LayerTree::Paint(CompositorContext::ScopedFrame& frame) const {
  Layer::PaintContext context = {*frame.canvas(),
                                 frame.context().frame_time(),
                                 frame.context().engine_time(),
                                 frame.context().memory_usage(),
                                 frame.context().texture_registry(),
                                 checkerboard_offscreen_layers_};
  TRACE_EVENT0("flutter", "LayerTree::Paint");

  if (root_layer_->needs_painting())
    root_layer_->Paint(context);
}

}  // namespace flow
