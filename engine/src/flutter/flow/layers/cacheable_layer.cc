// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/cacheable_layer.h"

namespace flutter {

AutoCache::AutoCache(RasterCacheItem* raster_cache_item,
                     PrerollContext* context,
                     const SkMatrix& matrix)
    : raster_cache_item_(raster_cache_item),
      context_(context),
      matrix_(matrix) {
  if (IsCacheEnabled()) {
    raster_cache_item->PrerollSetup(context, matrix);
  }
}

bool AutoCache::IsCacheEnabled() {
  return raster_cache_item_ && context_ && context_->raster_cache;
}

AutoCache::~AutoCache() {
  if (IsCacheEnabled()) {
    raster_cache_item_->PrerollFinalize(context_, matrix_);
  }
}

CacheableContainerLayer::CacheableContainerLayer(int layer_cached_threshold,
                                                 bool can_cache_children) {
  layer_raster_cache_item_ = LayerRasterCacheItem::Make(
      this, layer_cached_threshold, can_cache_children);
}

}  // namespace flutter
