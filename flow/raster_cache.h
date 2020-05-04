// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_H_
#define FLUTTER_FLOW_RASTER_CACHE_H_

#include <memory>
#include <unordered_map>

#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache_key.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class RasterCacheResult {
 public:
  RasterCacheResult() = default;

  RasterCacheResult(const RasterCacheResult& other) = default;

  RasterCacheResult(sk_sp<SkImage> image, const SkRect& logical_rect);

  operator bool() const { return static_cast<bool>(image_); }

  bool is_valid() const { return static_cast<bool>(image_); };

  void draw(SkCanvas& canvas, const SkPaint* paint = nullptr) const;

  SkISize image_dimensions() const {
    return image_ ? image_->dimensions() : SkISize::Make(0, 0);
  };

 private:
  sk_sp<SkImage> image_;
  SkRect logical_rect_;
};

struct PrerollContext;

class RasterCache {
 public:
  // The default max number of picture raster caches to be generated per frame.
  // Generating too many caches in one frame may cause jank on that frame. This
  // limit allows us to throttle the cache and distribute the work across
  // multiple frames.
  static constexpr int kDefaultPictureCacheLimitPerFrame = 3;

  explicit RasterCache(
      size_t access_threshold = 3,
      size_t picture_cache_limit_per_frame = kDefaultPictureCacheLimitPerFrame);

  static SkIRect GetDeviceBounds(const SkRect& rect, const SkMatrix& ctm) {
    SkRect device_rect;
    ctm.mapRect(&device_rect, rect);
    SkIRect bounds;
    device_rect.roundOut(&bounds);
    return bounds;
  }

  static SkMatrix GetIntegralTransCTM(const SkMatrix& ctm) {
    SkMatrix result = ctm;
    result[SkMatrix::kMTransX] = SkScalarRoundToScalar(ctm.getTranslateX());
    result[SkMatrix::kMTransY] = SkScalarRoundToScalar(ctm.getTranslateY());
    return result;
  }

  // Return true if the cache is generated.
  //
  // We may return false and not generate the cache if
  // 1. The picture is not worth rasterizing
  // 2. The matrix is singular
  // 3. The picture is accessed too few times
  // 4. There are too many pictures to be cached in the current frame.
  //    (See also kDefaultPictureCacheLimitPerFrame.)
  bool Prepare(GrContext* context,
               SkPicture* picture,
               const SkMatrix& transformation_matrix,
               SkColorSpace* dst_color_space,
               bool is_complex,
               bool will_change);

  void Prepare(PrerollContext* context, Layer* layer, const SkMatrix& ctm);

  // Find the raster cache for the picture and draw it to the canvas.
  //
  // Return true if it's found and drawn.
  bool Draw(const SkPicture& picture, SkCanvas& canvas) const;

  // Find the raster cache for the layer and draw it to the canvas.
  //
  // Addional paint can be given to change how the raster cache is drawn (e.g.,
  // draw the raster cache with some opacity).
  //
  // Return true if the layer raster cache is found and drawn.
  bool Draw(const Layer* layer,
            SkCanvas& canvas,
            SkPaint* paint = nullptr) const;

  void SweepAfterFrame();

  void Clear();

  void SetCheckboardCacheImages(bool checkerboard);

  size_t GetCachedEntriesCount() const;

 private:
  struct Entry {
    bool used_this_frame = false;
    size_t access_count = 0;
    RasterCacheResult image;
  };

  template <class Cache>
  static void SweepOneCacheAfterFrame(Cache& cache) {
    std::vector<typename Cache::iterator> dead;

    for (auto it = cache.begin(); it != cache.end(); ++it) {
      Entry& entry = it->second;
      if (!entry.used_this_frame) {
        dead.push_back(it);
      }
      entry.used_this_frame = false;
    }

    for (auto it : dead) {
      cache.erase(it);
    }
  }

  const size_t access_threshold_;
  const size_t picture_cache_limit_per_frame_;
  size_t picture_cached_this_frame_ = 0;
  mutable PictureRasterCacheKey::Map<Entry> picture_cache_;
  mutable LayerRasterCacheKey::Map<Entry> layer_cache_;
  bool checkerboard_images_;

  void TraceStatsToTimeline() const;

  FML_DISALLOW_COPY_AND_ASSIGN(RasterCache);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_RASTER_CACHE_H_
