// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CACHEABLE_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CACHEABLE_LAYER_H_

#include <memory>

#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer_raster_cache_item.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

class CacheableLayer {
 protected:
  virtual RasterCacheItem* realize_raster_cache_item() = 0;
  virtual void disable_raster_cache_item() = 0;

  friend class AutoCache;
};

class AutoCache {
 public:
  AutoCache(CacheableLayer& item_provider,
            PrerollContext* context,
            bool caching_enabled = true);

  void ShouldNotBeCached() { raster_cache_item_ = nullptr; }

  ~AutoCache();

 private:
  RasterCacheItem* raster_cache_item_ = nullptr;
  PrerollContext* context_ = nullptr;
  SkMatrix matrix_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(AutoCache);
};

class CacheableContainerLayer : public ContainerLayer, public CacheableLayer {
 public:
  explicit CacheableContainerLayer(
      int layer_cached_threshold =
          RasterCacheUtil::kMinimumRendersBeforeCachingFilterLayer,
      bool can_cache_children = false)
      : layer_cache_threshold_(layer_cached_threshold),
        can_cache_children_(can_cache_children) {}

  const LayerRasterCacheItem* raster_cache_item() const {
    return layer_raster_cache_item_.get();
  }

  void MarkCanCacheChildren(bool can_cache_children) {
    if (layer_raster_cache_item_) {
      layer_raster_cache_item_->MarkCanCacheChildren(can_cache_children);
    }
  }

 protected:
  RasterCacheItem* realize_raster_cache_item() override;
  virtual void disable_raster_cache_item() override;
  std::unique_ptr<LayerRasterCacheItem> layer_raster_cache_item_;

  int layer_cache_threshold_;
  bool can_cache_children_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CACHEABLE_LAYER_H_
