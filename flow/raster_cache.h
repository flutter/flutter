// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_H_
#define FLUTTER_FLOW_RASTER_CACHE_H_

#include <memory>
#include <unordered_map>

#include "flutter/flow/instrumentation.h"
#include "flutter/flow/raster_cache_key.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#if defined(OS_FUCHSIA)
#include <fuchsia/cpp/ui.h>
#endif
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flow {

class RasterCacheResult {
 public:
  RasterCacheResult()
      : source_rect_(SkRect::MakeEmpty()),
        destination_rect_(SkRect::MakeEmpty()) {}

  RasterCacheResult(sk_sp<SkImage> image, SkRect source, SkRect destination)
      : image_(std::move(image)),
        source_rect_(source),
        destination_rect_(destination) {}

  operator bool() const { return static_cast<bool>(image_); }

  bool is_valid() const { return static_cast<bool>(image_); };

  sk_sp<SkImage> image() const { return image_; }

  const SkRect& source_rect() const { return source_rect_; }

  const SkRect& destination_rect() const { return destination_rect_; }

 private:
  sk_sp<SkImage> image_;
  SkRect source_rect_;
  SkRect destination_rect_;
};

class RasterCache {
 public:
  explicit RasterCache(size_t threshold = 3);

  ~RasterCache();

  RasterCacheResult GetPrerolledImage(GrContext* context,
                                      SkPicture* picture,
                                      const SkMatrix& transformation_matrix,
                                      SkColorSpace* dst_color_space,
#if defined(OS_FUCHSIA)
                                      gfx::Metrics* metrics,
#endif
                                      bool is_complex,
                                      bool will_change);

  void SweepAfterFrame();

  void Clear();

  void SetCheckboardCacheImages(bool checkerboard);

 private:
  struct Entry {
    bool used_this_frame = false;
    size_t access_count = 0;
    RasterCacheResult image;
  };

  const size_t threshold_;
  RasterCacheKey::Map<Entry> cache_;
  bool checkerboard_images_;
  fxl::WeakPtrFactory<RasterCache> weak_factory_;

  FXL_DISALLOW_COPY_AND_ASSIGN(RasterCache);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_RASTER_CACHE_H_
