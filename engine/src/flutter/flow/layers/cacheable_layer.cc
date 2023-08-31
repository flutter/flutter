// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/cacheable_layer.h"

namespace flutter {

AutoCache::AutoCache(CacheableLayer& cacheable_layer,
                     PrerollContext* context,
                     bool caching_enabled) {
  if (context->raster_cache && caching_enabled) {
    raster_cache_item_ = cacheable_layer.realize_raster_cache_item();
    if (raster_cache_item_) {
      context_ = context;
      matrix_ = context->state_stack.transform_3x3();
      raster_cache_item_->PrerollSetup(context_, matrix_);
    }
  } else {
    cacheable_layer.disable_raster_cache_item();
  }
}

AutoCache::~AutoCache() {
  if (raster_cache_item_) {
    raster_cache_item_->PrerollFinalize(context_, matrix_);
  }
}

RasterCacheItem* CacheableContainerLayer::realize_raster_cache_item() {
  if (!layer_raster_cache_item_) {
    layer_raster_cache_item_ = LayerRasterCacheItem::Make(
        this, layer_cache_threshold_, can_cache_children_);
  }
  return layer_raster_cache_item_.get();
}

void CacheableContainerLayer::disable_raster_cache_item() {
  if (layer_raster_cache_item_) {
    layer_raster_cache_item_->reset_cache_state();
  }
}

}  // namespace flutter
