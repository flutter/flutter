// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include <vector>

#include "flutter/flow/paint_utils.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorSpaceXformCanvas.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flow {

void RasterCacheResult::draw(SkCanvas& canvas) const {
  SkAutoCanvasRestore auto_restore(&canvas, true);
  SkIRect bounds =
      RasterCache::GetDeviceBounds(logical_rect_, canvas.getTotalMatrix());
  FML_DCHECK(bounds.size() == image_->dimensions());
  canvas.resetMatrix();
  canvas.drawImage(image_, bounds.fLeft, bounds.fTop);
}

RasterCache::RasterCache(size_t threshold)
    : threshold_(threshold), checkerboard_images_(false), weak_factory_(this) {}

RasterCache::~RasterCache() = default;

static bool CanRasterizePicture(SkPicture* picture) {
  if (picture == nullptr) {
    return false;
  }

  const SkRect cull_rect = picture->cullRect();

  if (cull_rect.isEmpty()) {
    // No point in ever rasterizing an empty picture.
    return false;
  }

  if (!cull_rect.isFinite()) {
    // Cannot attempt to rasterize into an infinitely large surface.
    return false;
  }

  return true;
}

static bool IsPictureWorthRasterizing(SkPicture* picture,
                                      bool will_change,
                                      bool is_complex) {
  if (will_change) {
    // If the picture is going to change in the future, there is no point in
    // doing to extra work to rasterize.
    return false;
  }

  if (!CanRasterizePicture(picture)) {
    // No point in deciding whether the picture is worth rasterizing if it
    // cannot be rasterized at all.
    return false;
  }

  if (is_complex) {
    // The caller seems to have extra information about the picture and thinks
    // the picture is always worth rasterizing.
    return true;
  }

  // TODO(abarth): We should find a better heuristic here that lets us avoid
  // wasting memory on trivial layers that are easy to re-rasterize every frame.
  return picture->approximateOpCount() > 10;
}

RasterCacheResult RasterizePicture(SkPicture* picture,
                                   GrContext* context,
                                   const SkMatrix& ctm,
                                   SkColorSpace* dst_color_space,
                                   bool checkerboard) {
  TRACE_EVENT0("flutter", "RasterCachePopulate");

  const SkRect logical_rect = picture->cullRect();
  SkIRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  const SkImageInfo image_info =
      SkImageInfo::MakeN32Premul(cache_rect.width(), cache_rect.height());

  sk_sp<SkSurface> surface =
      context
          ? SkSurface::MakeRenderTarget(context, SkBudgeted::kYes, image_info)
          : SkSurface::MakeRaster(image_info);

  if (!surface) {
    return {};
  }

  SkCanvas* canvas = surface->getCanvas();
  std::unique_ptr<SkCanvas> xformCanvas;
  if (dst_color_space) {
    xformCanvas = SkCreateColorSpaceXformCanvas(surface->getCanvas(),
                                                sk_ref_sp(dst_color_space));
    if (xformCanvas) {
      canvas = xformCanvas.get();
    }
  }

  canvas->clear(SK_ColorTRANSPARENT);
  canvas->translate(-cache_rect.left(), -cache_rect.top());
  canvas->concat(ctm);
  canvas->drawPicture(picture);

  if (checkerboard) {
    DrawCheckerboard(canvas, logical_rect);
  }

  return {surface->makeImageSnapshot(), logical_rect};
}

static inline size_t ClampSize(size_t value, size_t min, size_t max) {
  if (value > max) {
    return max;
  }

  if (value < min) {
    return min;
  }

  return value;
}

RasterCacheResult RasterCache::GetPrerolledImage(
    GrContext* context,
    SkPicture* picture,
    const SkMatrix& transformation_matrix,
    SkColorSpace* dst_color_space,
    bool is_complex,
    bool will_change) {
  if (!IsPictureWorthRasterizing(picture, will_change, is_complex)) {
    // We only deal with pictures that are worthy of rasterization.
    return {};
  }

  // Decompose the matrix (once) for all subsequent operations. We want to make
  // sure to avoid volumetric distortions while accounting for scaling.
  const MatrixDecomposition matrix(transformation_matrix);

  if (!matrix.IsValid()) {
    // The matrix was singular. No point in going further.
    return {};
  }

  RasterCacheKey cache_key(*picture, transformation_matrix);

  Entry& entry = cache_[cache_key];
  entry.access_count = ClampSize(entry.access_count + 1, 0, threshold_);
  entry.used_this_frame = true;

  if (entry.access_count < threshold_ || threshold_ == 0) {
    // Frame threshold has not yet been reached.
    return {};
  }

  if (!entry.image.is_valid()) {
    entry.image = RasterizePicture(picture, context, transformation_matrix,
                                   dst_color_space, checkerboard_images_);
  }

  return entry.image;
}

void RasterCache::SweepAfterFrame() {
  std::vector<RasterCacheKey::Map<Entry>::iterator> dead;

  for (auto it = cache_.begin(); it != cache_.end(); ++it) {
    Entry& entry = it->second;
    if (!entry.used_this_frame) {
      dead.push_back(it);
    }
    entry.used_this_frame = false;
  }

  for (auto it : dead) {
    cache_.erase(it);
  }
}

void RasterCache::Clear() {
  cache_.clear();
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

}  // namespace flow
