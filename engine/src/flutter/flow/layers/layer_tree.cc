// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/frame_timings.h"
#include "flutter/flow/layer_snapshot_store.h"
#include "flutter/flow/layers/cacheable_layer.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"
#include "include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flutter {

LayerTree::LayerTree(const SkISize& frame_size, float device_pixel_ratio)
    : frame_size_(frame_size),
      device_pixel_ratio_(device_pixel_ratio),
      rasterizer_tracing_threshold_(0),
      checkerboard_raster_cache_images_(false),
      checkerboard_offscreen_layers_(false) {
  FML_CHECK(device_pixel_ratio_ != 0.0f);
}

inline SkColorSpace* GetColorSpace(SkCanvas* canvas) {
  return canvas ? canvas->imageInfo().colorSpace() : nullptr;
}

bool LayerTree::Preroll(CompositorContext::ScopedFrame& frame,
                        bool ignore_raster_cache,
                        SkRect cull_rect) {
  TRACE_EVENT0("flutter", "LayerTree::Preroll");

  if (!root_layer_) {
    FML_LOG(ERROR) << "The scene did not specify any layers.";
    return false;
  }

  SkColorSpace* color_space = GetColorSpace(frame.canvas());
  frame.context().raster_cache().SetCheckboardCacheImages(
      checkerboard_raster_cache_images_);
  MutatorsStack stack;
  RasterCache* cache =
      ignore_raster_cache ? nullptr : &frame.context().raster_cache();
  raster_cache_items_.clear();

  PrerollContext context = {
      // clang-format off
      .raster_cache                  = cache,
      .gr_context                    = frame.gr_context(),
      .view_embedder                 = frame.view_embedder(),
      .mutators_stack                = stack,
      .dst_color_space               = color_space,
      .cull_rect                     = cull_rect,
      .surface_needs_readback        = false,
      .raster_time                   = frame.context().raster_time(),
      .ui_time                       = frame.context().ui_time(),
      .texture_registry              = frame.context().texture_registry(),
      .checkerboard_offscreen_layers = checkerboard_offscreen_layers_,
      .frame_device_pixel_ratio      = device_pixel_ratio_,
      .raster_cached_entries         = &raster_cache_items_,
      // clang-format on
  };

  root_layer_->Preroll(&context, frame.root_surface_transformation());

  return context.surface_needs_readback;
}

void LayerTree::TryToRasterCache(
    const std::vector<RasterCacheItem*>& raster_cached_items,
    const PaintContext* paint_context,
    bool ignore_raster_cache) {
  unsigned i = 0;
  const auto item_size = raster_cached_items.size();
  while (i < item_size) {
    auto* item = raster_cached_items[i];
    if (item->need_caching()) {
      // try to cache current layer
      // If parent failed to cache, just proceed to the next entry
      // cache current entry, this entry's parent must not cache
      if (item->TryToPrepareRasterCache(*paint_context, false)) {
        // if parent cached, then foreach child layer to touch them.
        for (unsigned j = 0; j < item->child_items(); j++) {
          auto* child_item = raster_cached_items[i + j + 1];
          if (child_item->need_caching()) {
            child_item->TryToPrepareRasterCache(*paint_context, true);
          }
        }
        i += item->child_items() + 1;
        continue;
      }
    }
    i++;
  }
}

void LayerTree::Paint(CompositorContext::ScopedFrame& frame,
                      bool ignore_raster_cache) const {
  TRACE_EVENT0("flutter", "LayerTree::Paint");

  if (!root_layer_) {
    FML_LOG(ERROR) << "The scene did not specify any layers to paint.";
    return;
  }

  SkISize canvas_size = frame.canvas()->getBaseLayerSize();
  SkNWayCanvas internal_nodes_canvas(canvas_size.width(), canvas_size.height());
  internal_nodes_canvas.addCanvas(frame.canvas());
  if (frame.view_embedder() != nullptr) {
    auto overlay_canvases = frame.view_embedder()->GetCurrentCanvases();
    for (size_t i = 0; i < overlay_canvases.size(); i++) {
      internal_nodes_canvas.addCanvas(overlay_canvases[i]);
    }
  }

  // clear the previous snapshots.
  LayerSnapshotStore* snapshot_store = nullptr;
  if (enable_leaf_layer_tracing_) {
    frame.context().snapshot_store().Clear();
    snapshot_store = &frame.context().snapshot_store();
  }

  SkColorSpace* color_space = GetColorSpace(frame.canvas());
  RasterCache* cache =
      ignore_raster_cache ? nullptr : &frame.context().raster_cache();
  PaintContext context = {
      // clang-format off
      .internal_nodes_canvas         = &internal_nodes_canvas,
      .leaf_nodes_canvas             = frame.canvas(),
      .gr_context                    = frame.gr_context(),
      .dst_color_space               = color_space,
      .view_embedder                 = frame.view_embedder(),
      .raster_time                   = frame.context().raster_time(),
      .ui_time                       = frame.context().ui_time(),
      .texture_registry              = frame.context().texture_registry(),
      .raster_cache                  = cache,
      .checkerboard_offscreen_layers = checkerboard_offscreen_layers_,
      .frame_device_pixel_ratio      = device_pixel_ratio_,
      .layer_snapshot_store          = snapshot_store,
      .enable_leaf_layer_tracing     = enable_leaf_layer_tracing_,
      .inherited_opacity             = SK_Scalar1,
      .leaf_nodes_builder            = frame.display_list_builder(),
      // clang-format on
  };

  if (cache) {
    TryToRasterCache(raster_cache_items_, &context, ignore_raster_cache);
  }

  if (root_layer_->needs_painting(context)) {
    root_layer_->Paint(context);
  }
}

sk_sp<DisplayList> LayerTree::Flatten(const SkRect& bounds) {
  TRACE_EVENT0("flutter", "LayerTree::Flatten");

  DisplayListCanvasRecorder builder(bounds);

  MutatorsStack unused_stack;
  const FixedRefreshRateStopwatch unused_stopwatch;
  TextureRegistry unused_texture_registry;
  SkMatrix root_surface_transformation;
  // No root surface transformation. So assume identity.
  root_surface_transformation.reset();

  PrerollContext preroll_context{
      // clang-format off
      .raster_cache                  = nullptr,
      .gr_context                    = nullptr,
      .view_embedder                 = nullptr,
      .mutators_stack                = unused_stack,
      .dst_color_space               = nullptr,
      .cull_rect                     = kGiantRect,
      .surface_needs_readback        = false,
      .raster_time                   = unused_stopwatch,
      .ui_time                       = unused_stopwatch,
      .texture_registry              = unused_texture_registry,
      .checkerboard_offscreen_layers = false,
      .frame_device_pixel_ratio      = device_pixel_ratio_
      // clang-format on
  };

  SkISize canvas_size = builder.getBaseLayerSize();
  SkNWayCanvas internal_nodes_canvas(canvas_size.width(), canvas_size.height());
  internal_nodes_canvas.addCanvas(&builder);

  PaintContext paint_context = {
      // clang-format off
      .internal_nodes_canvas         = &internal_nodes_canvas,
      .leaf_nodes_canvas             = &builder,
      .gr_context                    = nullptr,
      .dst_color_space               = nullptr,
      .view_embedder                 = nullptr,
      .raster_time                   = unused_stopwatch,
      .ui_time                       = unused_stopwatch,
      .texture_registry              = unused_texture_registry,
      .raster_cache                  = nullptr,
      .checkerboard_offscreen_layers = false,
      .frame_device_pixel_ratio      = device_pixel_ratio_,
      .layer_snapshot_store          = nullptr,
      .enable_leaf_layer_tracing     = false,
      .leaf_nodes_builder            = builder.builder().get(),
      // clang-format on
  };

  // Even if we don't have a root layer, we still need to create an empty
  // picture.
  if (root_layer_) {
    root_layer_->Preroll(&preroll_context, root_surface_transformation);
    // The needs painting flag may be set after the preroll. So check it after.
    if (root_layer_->needs_painting(paint_context)) {
      root_layer_->Paint(paint_context);
    }
  }

  return builder.Build();
}

}  // namespace flutter
