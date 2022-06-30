// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include <cstddef>
#include <vector>

#include "flutter/common/constants.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/flow/raster_cache_util.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

RasterCacheResult::RasterCacheResult(sk_sp<SkImage> image,
                                     const SkRect& logical_rect,
                                     const char* type)
    : image_(std::move(image)), logical_rect_(logical_rect), flow_(type) {}

void RasterCacheResult::draw(SkCanvas& canvas, const SkPaint* paint) const {
  TRACE_EVENT0("flutter", "RasterCacheResult::draw");
  SkAutoCanvasRestore auto_restore(&canvas, true);

  SkRect bounds =
      RasterCacheUtil::GetDeviceBounds(logical_rect_, canvas.getTotalMatrix());
  FML_DCHECK(std::abs(bounds.width() - image_->dimensions().width()) <= 1 &&
             std::abs(bounds.height() - image_->dimensions().height()) <= 1);
  canvas.resetMatrix();
  flow_.Step();
  canvas.drawImage(image_, bounds.fLeft, bounds.fTop, SkSamplingOptions(),
                   paint);
}

RasterCache::RasterCache(size_t access_threshold,
                         size_t display_list_cache_limit_per_frame)
    : access_threshold_(access_threshold),
      display_list_cache_limit_per_frame_(display_list_cache_limit_per_frame),
      checkerboard_images_(false) {}

/// @note Procedure doesn't copy all closures.
std::unique_ptr<RasterCacheResult> RasterCache::Rasterize(
    const RasterCache::Context& context,
    const std::function<void(SkCanvas*)>& draw_function) {
  TRACE_EVENT0("flutter", "RasterCachePopulate");

  SkRect dest_rect =
      RasterCacheUtil::GetDeviceBounds(context.logical_rect, context.matrix);
  // we always round out here so that the texture is integer sized.
  int width = SkScalarCeilToInt(dest_rect.width());
  int height = SkScalarCeilToInt(dest_rect.height());

  const SkImageInfo image_info = SkImageInfo::MakeN32Premul(
      width, height, sk_ref_sp(context.dst_color_space));

  sk_sp<SkSurface> surface =
      context.gr_context ? SkSurface::MakeRenderTarget(
                               context.gr_context, SkBudgeted::kYes, image_info)
                         : SkSurface::MakeRaster(image_info);

  if (!surface) {
    return nullptr;
  }

  SkCanvas* canvas = surface->getCanvas();
  canvas->clear(SK_ColorTRANSPARENT);
  canvas->translate(-dest_rect.left(), -dest_rect.top());
  canvas->concat(context.matrix);
  draw_function(canvas);

  if (context.checkerboard) {
    DrawCheckerboard(canvas, context.logical_rect);
  }

  return std::make_unique<RasterCacheResult>(
      surface->makeImageSnapshot(), context.logical_rect, context.flow_type);
}

bool RasterCache::UpdateCacheEntry(
    const RasterCacheKeyID& id,
    const Context& raster_cache_context,
    const std::function<void(SkCanvas*)>& render_function) const {
  RasterCacheKey key = RasterCacheKey(id, raster_cache_context.matrix);
  Entry& entry = cache_[key];
  entry.used_this_frame = true;
  if (!entry.image) {
    entry.image = Rasterize(raster_cache_context, render_function);
    if (entry.image != nullptr) {
      switch (id.type()) {
        case RasterCacheKeyType::kDisplayList: {
          display_list_cached_this_frame_++;
          break;
        }
        default:
          break;
      }
      return true;
    }
  }
  return entry.image != nullptr;
}

bool RasterCache::Touch(const RasterCacheKeyID& id,
                        const SkMatrix& matrix) const {
  RasterCacheKey cache_key = RasterCacheKey(id, matrix);
  auto it = cache_.find(cache_key);
  if (it != cache_.end()) {
    it->second.access_count++;
    it->second.used_this_frame = true;
    return true;
  }
  return false;
}

int RasterCache::MarkSeen(const RasterCacheKeyID& id,
                          const SkMatrix& matrix) const {
  RasterCacheKey key = RasterCacheKey(id, matrix);
  Entry& entry = cache_[key];
  entry.used_this_frame = true;
  return entry.access_count;
}

bool RasterCache::HasEntry(const RasterCacheKeyID& id,
                           const SkMatrix& matrix) const {
  RasterCacheKey key = RasterCacheKey(id, matrix);
  if (cache_.find(key) != cache_.cend()) {
    return true;
  }
  return false;
}

bool RasterCache::Draw(const RasterCacheKeyID& id,
                       SkCanvas& canvas,
                       const SkPaint* paint) const {
  auto it = cache_.find(RasterCacheKey(id, canvas.getTotalMatrix()));
  if (it == cache_.end()) {
    return false;
  }

  Entry& entry = it->second;
  entry.access_count++;
  entry.used_this_frame = true;

  if (entry.image) {
    entry.image->draw(canvas, paint);
    return true;
  }

  return false;
}

void RasterCache::PrepareNewFrame() {
  display_list_cached_this_frame_ = 0;
}

void RasterCache::SweepOneCacheAfterFrame(RasterCacheKey::Map<Entry>& cache,
                                          RasterCacheMetrics& picture_metrics,
                                          RasterCacheMetrics& layer_metrics) {
  std::vector<RasterCacheKey::Map<Entry>::iterator> dead;

  for (auto it = cache.begin(); it != cache.end(); ++it) {
    Entry& entry = it->second;

    if (!entry.used_this_frame) {
      dead.push_back(it);
    } else if (entry.image) {
      RasterCacheKeyKind kind = it->first.kind();
      switch (kind) {
        case RasterCacheKeyKind::kDisplayListMetrics:
          picture_metrics.in_use_count++;
          picture_metrics.in_use_bytes += entry.image->image_bytes();
          break;
        case RasterCacheKeyKind::kLayerMetrics:
          layer_metrics.in_use_count++;
          layer_metrics.in_use_bytes += entry.image->image_bytes();
          break;
      }
    }
    entry.used_this_frame = false;
  }

  for (auto it : dead) {
    if (it->second.image) {
      RasterCacheKeyKind kind = it->first.kind();
      switch (kind) {
        case RasterCacheKeyKind::kDisplayListMetrics:
          picture_metrics.eviction_count++;
          picture_metrics.eviction_bytes += it->second.image->image_bytes();
          break;
        case RasterCacheKeyKind::kLayerMetrics:
          layer_metrics.eviction_count++;
          layer_metrics.eviction_bytes += it->second.image->image_bytes();
          break;
      }
    }
    cache.erase(it);
  }
}

void RasterCache::CleanupAfterFrame() {
  picture_metrics_ = {};
  layer_metrics_ = {};
  SweepOneCacheAfterFrame(cache_, picture_metrics_, layer_metrics_);
  TraceStatsToTimeline();
}

void RasterCache::Clear() {
  cache_.clear();
  picture_metrics_ = {};
  layer_metrics_ = {};
}

size_t RasterCache::GetCachedEntriesCount() const {
  return cache_.size();
}

size_t RasterCache::GetLayerCachedEntriesCount() const {
  size_t layer_cached_entries_count = 0;
  for (const auto& item : cache_) {
    if (item.first.kind() == RasterCacheKeyKind::kLayerMetrics) {
      layer_cached_entries_count++;
    }
  }
  return layer_cached_entries_count;
}

size_t RasterCache::GetPictureCachedEntriesCount() const {
  size_t display_list_cached_entries_count = 0;
  for (const auto& item : cache_) {
    if (item.first.kind() == RasterCacheKeyKind::kDisplayListMetrics) {
      display_list_cached_entries_count++;
    }
  }
  return display_list_cached_entries_count;
}

void RasterCache::SetCheckboardCacheImages(bool checkerboard) {
  if (checkerboard_images_ == checkerboard) {
    return;
  }

  checkerboard_images_ = checkerboard;

  // Clear all existing entries so previously rasterized items (with or without
  // a checkerboard) will be refreshed in subsequent passes.
  Clear();
}

void RasterCache::TraceStatsToTimeline() const {
#if !FLUTTER_RELEASE
  FML_TRACE_COUNTER(
      "flutter",                                                           //
      "RasterCache", reinterpret_cast<int64_t>(this),                      //
      "LayerCount", layer_metrics_.total_count(),                          //
      "LayerMBytes", layer_metrics_.total_bytes() / kMegaByteSizeInBytes,  //
      "PictureCount", picture_metrics_.total_count(),                      //
      "PictureMBytes", picture_metrics_.total_bytes() / kMegaByteSizeInBytes);

#endif  // !FLUTTER_RELEASE
}

size_t RasterCache::EstimateLayerCacheByteSize() const {
  size_t layer_cache_bytes = 0;
  for (const auto& item : cache_) {
    if (item.first.kind() == RasterCacheKeyKind::kLayerMetrics &&
        item.second.image) {
      layer_cache_bytes += item.second.image->image_bytes();
    }
  }
  return layer_cache_bytes;
}

size_t RasterCache::EstimatePictureCacheByteSize() const {
  size_t picture_cache_bytes = 0;
  for (const auto& item : cache_) {
    if (item.first.kind() == RasterCacheKeyKind::kDisplayListMetrics &&
        item.second.image) {
      picture_cache_bytes += item.second.image->image_bytes();
    }
  }
  return picture_cache_bytes;
}

}  // namespace flutter
