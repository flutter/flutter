// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/raster_cache.h"

#include "sky/compositor/paint_context.h"
#include "base/logging.h"
#include "third_party/skia/include/core/SkImage.h"

namespace sky {
namespace compositor {

static const int kRasterThreshold = 3;

static bool isWorthRasterizing(SkPicture* picture) {
  // TODO(abarth): We should find a better heuristic here that lets us avoid
  // wasting memory on trivial layers that are easy to re-rasterize every frame.
  return picture->approximateOpCount() > 10 || picture->hasText();
}

RasterCache::RasterCache() {
}

RasterCache::~RasterCache() {
}

RasterCache::Entry::Entry() {
  physical_size.setEmpty();
}

RasterCache::Entry::~Entry() {
}

RefPtr<SkImage> RasterCache::GetImage(
    SkPicture* picture, const SkISize& physical_size) {
  if (physical_size.isEmpty())
    return nullptr;

  Entry& entry = cache_[picture->uniqueID()];

  const bool size_matched = entry.physical_size == physical_size;

  entry.used_this_frame = true;
  entry.physical_size = physical_size;

  if (!size_matched) {
    entry.access_count = 1;
    entry.image = nullptr;
    return nullptr;
  }

  entry.access_count++;

  if (entry.access_count >= kRasterThreshold) {
    // Saturate at the threshhold.
    entry.access_count = kRasterThreshold;

    if (!entry.image && isWorthRasterizing(picture)) {
      entry.image = adoptRef(SkImage::NewFromPicture(picture, physical_size,
                                                     nullptr, nullptr));
    }
  }

  return entry.image;
}

void RasterCache::SweepAfterFrame() {
  std::vector<Cache::iterator> dead;

  for (auto it = cache_.begin(); it != cache_.end(); ++it) {
    Entry& entry = it->second;
    if (!entry.used_this_frame)
      dead.push_back(it);
    entry.used_this_frame = false;
  }

  for (auto it : dead)
    cache_.erase(it);
}

}  // namespace compositor
}  // namespace sky
