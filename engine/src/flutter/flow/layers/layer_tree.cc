// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_tree.h"

#include "flutter/display_list/skia/dl_sk_canvas.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/frame_timings.h"
#include "flutter/flow/layer_snapshot_store.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"
#include "include/core/SkColorSpace.h"

namespace flutter {

LayerTree::LayerTree(const Config& config, const SkISize& frame_size)
    : root_layer_(config.root_layer),
      frame_size_(frame_size),
      rasterizer_tracing_threshold_(config.rasterizer_tracing_threshold),
      checkerboard_raster_cache_images_(
          config.checkerboard_raster_cache_images),
      checkerboard_offscreen_layers_(config.checkerboard_offscreen_layers) {}

inline SkColorSpace* GetColorSpace(DlCanvas* canvas) {
  return canvas ? canvas->GetImageInfo().colorSpace() : nullptr;
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
  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(cull_rect,
                                   frame.root_surface_transformation());
  RasterCache* cache =
      ignore_raster_cache ? nullptr : &frame.context().raster_cache();
  raster_cache_items_.clear();

  PrerollContext context = {
      // clang-format off
      .raster_cache                  = cache,
      .gr_context                    = frame.gr_context(),
      .view_embedder                 = frame.view_embedder(),
      .state_stack                   = state_stack,
      .dst_color_space               = sk_ref_sp<SkColorSpace>(color_space),
      .surface_needs_readback        = false,
      .raster_time                   = frame.context().raster_time(),
      .ui_time                       = frame.context().ui_time(),
      .texture_registry              = frame.context().texture_registry(),
      .raster_cached_entries         = &raster_cache_items_,
      // clang-format on
  };

  root_layer_->Preroll(&context);

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

  LayerStateStack state_stack;

  // DrawCheckerboard is not supported on Impeller.
  if (checkerboard_offscreen_layers_ && !frame.aiks_context()) {
    state_stack.set_checkerboard_func(DrawCheckerboard);
  }

  DlCanvas* canvas = frame.canvas();
  state_stack.set_delegate(canvas);

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
      .state_stack                   = state_stack,
      .canvas                        = canvas,
      .gr_context                    = frame.gr_context(),
      .dst_color_space               = sk_ref_sp(color_space),
      .view_embedder                 = frame.view_embedder(),
      .raster_time                   = frame.context().raster_time(),
      .ui_time                       = frame.context().ui_time(),
      .texture_registry              = frame.context().texture_registry(),
      .raster_cache                  = cache,
      .layer_snapshot_store          = snapshot_store,
      .enable_leaf_layer_tracing     = enable_leaf_layer_tracing_,
      .impeller_enabled              = !!frame.aiks_context(),
      .aiks_context                  = frame.aiks_context(),
      // clang-format on
  };

  if (cache) {
    cache->EvictUnusedCacheEntries();
    TryToRasterCache(raster_cache_items_, &context, ignore_raster_cache);
  }

  if (root_layer_->needs_painting(context)) {
    root_layer_->Paint(context);
  }
}

sk_sp<DisplayList> LayerTree::Flatten(
    const SkRect& bounds,
    const std::shared_ptr<TextureRegistry>& texture_registry,
    GrDirectContext* gr_context) {
  TRACE_EVENT0("flutter", "LayerTree::Flatten");

  DisplayListBuilder builder(bounds);

  const FixedRefreshRateStopwatch unused_stopwatch;

  LayerStateStack preroll_state_stack;
  // No root surface transformation. So assume identity.
  preroll_state_stack.set_preroll_delegate(bounds);
  PrerollContext preroll_context{
      // clang-format off
      .raster_cache                  = nullptr,
      .gr_context                    = gr_context,
      .view_embedder                 = nullptr,
      .state_stack                   = preroll_state_stack,
      .dst_color_space               = nullptr,
      .surface_needs_readback        = false,
      .raster_time                   = unused_stopwatch,
      .ui_time                       = unused_stopwatch,
      .texture_registry              = texture_registry,
      // clang-format on
  };

  LayerStateStack paint_state_stack;
  paint_state_stack.set_delegate(&builder);
  PaintContext paint_context = {
      // clang-format off
      .state_stack                   = paint_state_stack,
      .canvas                        = &builder,
      .gr_context                    = gr_context,
      .dst_color_space               = nullptr,
      .view_embedder                 = nullptr,
      .raster_time                   = unused_stopwatch,
      .ui_time                       = unused_stopwatch,
      .texture_registry              = texture_registry,
      .raster_cache                  = nullptr,
      .layer_snapshot_store          = nullptr,
      .enable_leaf_layer_tracing     = false,
      // clang-format on
  };

  // Even if we don't have a root layer, we still need to create an empty
  // picture.
  if (root_layer_) {
    root_layer_->Preroll(&preroll_context);

    // The needs painting flag may be set after the preroll. So check it after.
    if (root_layer_->needs_painting(paint_context)) {
      root_layer_->Paint(paint_context);
    }
  }

  return builder.Build();
}

}  // namespace flutter
