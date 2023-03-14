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
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSize.h"

class GrDirectContext;

namespace flutter {

class LayerTree {
 public:
  LayerTree(const SkISize& frame_size, float device_pixel_ratio);

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

  void set_root_layer(std::shared_ptr<Layer> root_layer) {
    root_layer_ = std::move(root_layer);
  }

  const SkISize& frame_size() const { return frame_size_; }
  float device_pixel_ratio() const { return device_pixel_ratio_; }

  const PaintRegionMap& paint_region_map() const { return paint_region_map_; }
  PaintRegionMap& paint_region_map() { return paint_region_map_; }

  // The number of frame intervals missed after which the compositor must
  // trace the rasterized picture to a trace file. Specify 0 to disable all
  // tracing
  void set_rasterizer_tracing_threshold(uint32_t interval) {
    rasterizer_tracing_threshold_ = interval;
  }

  uint32_t rasterizer_tracing_threshold() const {
    return rasterizer_tracing_threshold_;
  }

  void set_checkerboard_raster_cache_images(bool checkerboard) {
    checkerboard_raster_cache_images_ = checkerboard;
  }

  void set_checkerboard_offscreen_layers(bool checkerboard) {
    checkerboard_offscreen_layers_ = checkerboard;
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
  const float device_pixel_ratio_;  // Logical / Physical pixels ratio.
  uint32_t rasterizer_tracing_threshold_;
  bool checkerboard_raster_cache_images_;
  bool checkerboard_offscreen_layers_;
  bool enable_leaf_layer_tracing_ = false;

  PaintRegionMap paint_region_map_;

  std::vector<RasterCacheItem*> raster_cache_items_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTree);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_TREE_H_
