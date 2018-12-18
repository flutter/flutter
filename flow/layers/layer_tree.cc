// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/flow/layers/layer.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flow {

LayerTree::LayerTree()
    : frame_size_{},
      rasterizer_tracing_threshold_(0),
      checkerboard_raster_cache_images_(false),
      checkerboard_offscreen_layers_(false) {}

LayerTree::~LayerTree() = default;

void LayerTree::Preroll(CompositorContext::ScopedFrame& frame,
                        bool ignore_raster_cache) {
  TRACE_EVENT0("flutter", "LayerTree::Preroll");
  SkColorSpace* color_space =
      frame.canvas() ? frame.canvas()->imageInfo().colorSpace() : nullptr;
  frame.context().raster_cache().SetCheckboardCacheImages(
      checkerboard_raster_cache_images_);
  PrerollContext context = {
      ignore_raster_cache ? nullptr : &frame.context().raster_cache(),
      frame.gr_context(),
      frame.view_embedder(),
      color_space,
      kGiantRect,
      frame.context().frame_time(),
      frame.context().engine_time(),
      frame.context().texture_registry(),
      checkerboard_offscreen_layers_};

  root_layer_->Preroll(&context, frame.root_surface_transformation());
}

#if defined(OS_FUCHSIA)
void LayerTree::UpdateScene(SceneUpdateContext& context,
                            scenic::ContainerNode& container) {
  TRACE_EVENT0("flutter", "LayerTree::UpdateScene");
  const auto& metrics = context.metrics();
  SceneUpdateContext::Transform transform(context,                  // context
                                          1.0f / metrics->scale_x,  // X
                                          1.0f / metrics->scale_y,  // Y
                                          1.0f / metrics->scale_z   // Z
  );
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

void LayerTree::Paint(CompositorContext::ScopedFrame& frame,
                      bool ignore_raster_cache) const {
  TRACE_EVENT0("flutter", "LayerTree::Paint");
  SkISize canvas_size = frame.canvas()->getBaseLayerSize();
  SkNWayCanvas internal_nodes_canvas(canvas_size.width(), canvas_size.height());
  internal_nodes_canvas.addCanvas(frame.canvas());
  if (frame.view_embedder() != nullptr) {
    auto overlay_canvases = frame.view_embedder()->GetCurrentCanvases();
    for (size_t i = 0; i < overlay_canvases.size(); i++) {
      internal_nodes_canvas.addCanvas(overlay_canvases[i]);
    }
  }

  Layer::PaintContext context = {
      (SkCanvas*)&internal_nodes_canvas,
      frame.canvas(),
      frame.view_embedder(),
      frame.context().frame_time(),
      frame.context().engine_time(),
      frame.context().texture_registry(),
      ignore_raster_cache ? nullptr : &frame.context().raster_cache(),
      checkerboard_offscreen_layers_};

  if (root_layer_->needs_painting())
    root_layer_->Paint(context);
}

sk_sp<SkPicture> LayerTree::Flatten(const SkRect& bounds) {
  TRACE_EVENT0("flutter", "LayerTree::Flatten");

  SkPictureRecorder recorder;
  auto* canvas = recorder.beginRecording(bounds);

  if (!canvas) {
    return nullptr;
  }

  const Stopwatch unused_stopwatch;
  TextureRegistry unused_texture_registry;
  SkMatrix root_surface_transformation;
  // No root surface transformation. So assume identity.
  root_surface_transformation.reset();

  PrerollContext preroll_context{
      nullptr,                  // raster_cache (don't consult the cache)
      nullptr,                  // gr_context  (used for the raster cache)
      nullptr,                  // external view embedder
      nullptr,                  // SkColorSpace* dst_color_space
      kGiantRect,               // SkRect cull_rect
      unused_stopwatch,         // frame time (dont care)
      unused_stopwatch,         // engine time (dont care)
      unused_texture_registry,  // texture registry (not supported)
      false,                    // checkerboard_offscreen_layers
  };

  SkISize canvas_size = canvas->getBaseLayerSize();
  SkNWayCanvas internal_nodes_canvas(canvas_size.width(), canvas_size.height());
  internal_nodes_canvas.addCanvas(canvas);

  Layer::PaintContext paint_context = {
      (SkCanvas*)&internal_nodes_canvas,
      canvas,  // canvas
      nullptr,
      unused_stopwatch,         // frame time (dont care)
      unused_stopwatch,         // engine time (dont care)
      unused_texture_registry,  // texture registry (not supported)
      nullptr,                  // raster cache
      false                     // checkerboard offscreen layers
  };

  // Even if we don't have a root layer, we still need to create an empty
  // picture.
  if (root_layer_) {
    root_layer_->Preroll(&preroll_context, root_surface_transformation);
    // The needs painting flag may be set after the preroll. So check it after.
    if (root_layer_->needs_painting()) {
      root_layer_->Paint(paint_context);
    }
  }

  return recorder.finishRecordingAsPicture();
}

}  // namespace flow
