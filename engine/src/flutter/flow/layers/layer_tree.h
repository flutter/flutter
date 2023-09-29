// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
#define FLUTTER_FLOW_LAYERS_LAYER_TREE_H_

#include <cstdint>
#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"

class GrDirectContext;

namespace flutter {

class LayerTree {
 public:
  struct Config {
    std::shared_ptr<Layer> root_layer;
    uint32_t rasterizer_tracing_threshold = 0;
    bool checkerboard_raster_cache_images = false;
    bool checkerboard_offscreen_layers = false;
  };

  LayerTree(const Config& config, const SkISize& frame_size);

  // Perform a preroll pass on the tree and return information about
  // the tree that affects rendering this frame.
  //
  // Returns:
  // - a boolean indicating whether or not the top level of the
  //   layer tree performs any operations that require readback
  //   from the root surface.
  bool Preroll(CompositorContext::ScopedFrame& frame,
               bool ignore_raster_cache = false,
               SkRect cull_rect = kGiantRect);

  static void TryToRasterCache(
      const std::vector<RasterCacheItem*>& raster_cached_entries,
      const PaintContext* paint_context,
      bool ignore_raster_cache = false);

  void Paint(CompositorContext::ScopedFrame& frame,
             bool ignore_raster_cache = false) const;

  sk_sp<DisplayList> Flatten(
      const SkRect& bounds,
      const std::shared_ptr<TextureRegistry>& texture_registry = nullptr,
      GrDirectContext* gr_context = nullptr);

  Layer* root_layer() const { return root_layer_.get(); }
  const SkISize& frame_size() const { return frame_size_; }

  const PaintRegionMap& paint_region_map() const { return paint_region_map_; }
  PaintRegionMap& paint_region_map() { return paint_region_map_; }

  // The number of frame intervals missed after which the compositor must
  // trace the rasterized picture to a trace file. 0 stands for disabling all
  // tracing.
  uint32_t rasterizer_tracing_threshold() const {
    return rasterizer_tracing_threshold_;
  }

  /// When `Paint` is called, if leaf layer tracing is enabled, additional
  /// metadata around raterization of leaf layers is collected.
  ///
  /// See: `LayerSnapshotStore`
  void enable_leaf_layer_tracing(bool enable) {
    enable_leaf_layer_tracing_ = enable;
  }

  bool is_leaf_layer_tracing_enabled() const {
    return enable_leaf_layer_tracing_;
  }

 private:
  std::shared_ptr<Layer> root_layer_;
  SkISize frame_size_ = SkISize::MakeEmpty();  // Physical pixels.
  uint32_t rasterizer_tracing_threshold_;
  bool checkerboard_raster_cache_images_;
  bool checkerboard_offscreen_layers_;
  bool enable_leaf_layer_tracing_ = false;

  PaintRegionMap paint_region_map_;

  std::vector<RasterCacheItem*> raster_cache_items_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTree);
};

// The information to draw a layer tree to a specified view.
struct LayerTreeTask {
 public:
  LayerTreeTask(int64_t view_id,
                std::unique_ptr<LayerTree> layer_tree,
                float device_pixel_ratio)
      : view_id(view_id),
        layer_tree(std::move(layer_tree)),
        device_pixel_ratio(device_pixel_ratio) {}

  /// The target view to draw to.
  int64_t view_id;
  /// The target layer tree to be drawn.
  std::unique_ptr<LayerTree> layer_tree;
  /// The pixel ratio of the target view.
  float device_pixel_ratio;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(LayerTreeTask);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
