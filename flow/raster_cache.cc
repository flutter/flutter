// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include <vector>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorSpaceXformCanvas.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flow {

void RasterCacheResult::draw(SkCanvas& canvas, const SkPaint* paint) const {
  SkAutoCanvasRestore auto_restore(&canvas, true);
  SkIRect bounds =
      RasterCache::GetDeviceBounds(logical_rect_, canvas.getTotalMatrix());
  FML_DCHECK(bounds.size() == image_->dimensions());
  canvas.resetMatrix();
  canvas.drawImage(image_, bounds.fLeft, bounds.fTop, paint);
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

static RasterCacheResult Rasterize(
    GrContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard,
    const SkRect& logical_rect,
    std::function<void(SkCanvas*)> draw_function) {
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
  draw_function(canvas);

  if (checkerboard) {
    DrawCheckerboard(canvas, logical_rect);
  }

  return {surface->makeImageSnapshot(), logical_rect};
}

RasterCacheResult RasterizePicture(SkPicture* picture,
                                   GrContext* context,
                                   const SkMatrix& ctm,
                                   SkColorSpace* dst_color_space,
                                   bool checkerboard) {
  TRACE_EVENT0("flutter", "RasterCachePopulate");

  return Rasterize(context, ctm, dst_color_space, checkerboard,
                   picture->cullRect(),
                   [=](SkCanvas* canvas) { canvas->drawPicture(picture); });
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

void RasterCache::Prepare(PrerollContext* context,
                          std::shared_ptr<Layer> layer,
                          const SkMatrix& ctm) {
  LayerRasterCacheKey cache_key(layer, ctm);
  Entry& entry = layer_cache_[cache_key];
  entry.access_count = ClampSize(entry.access_count + 1, 0, threshold_);
  entry.used_this_frame = true;
  if (!entry.image.is_valid()) {
    entry.image = Rasterize(context->gr_context, ctm, context->dst_color_space,
                            checkerboard_images_, layer->paint_bounds(),
                            [layer, context](SkCanvas* canvas) {
                              Layer::PaintContext paintContext = {
                                  *canvas,
                                  context->frame_time,
                                  context->engine_time,
                                  context->texture_registry,
                                  context->raster_cache,
                                  context->checkerboard_offscreen_layers};
                              layer->Paint(paintContext);
                            });
  }
}

bool RasterCache::Prepare(GrContext* context,
                          SkPicture* picture,
                          const SkMatrix& transformation_matrix,
                          SkColorSpace* dst_color_space,
                          bool is_complex,
                          bool will_change) {
  if (!IsPictureWorthRasterizing(picture, will_change, is_complex)) {
    // We only deal with pictures that are worthy of rasterization.
    return false;
  }

  // Decompose the matrix (once) for all subsequent operations. We want to make
  // sure to avoid volumetric distortions while accounting for scaling.
  const MatrixDecomposition matrix(transformation_matrix);

  if (!matrix.IsValid()) {
    // The matrix was singular. No point in going further.
    return false;
  }

  PictureRasterCacheKey cache_key(picture->uniqueID(), transformation_matrix);

  Entry& entry = picture_cache_[cache_key];
  entry.access_count = ClampSize(entry.access_count + 1, 0, threshold_);
  entry.used_this_frame = true;

  if (entry.access_count < threshold_ || threshold_ == 0) {
    // Frame threshold has not yet been reached.
    return false;
  }

  if (!entry.image.is_valid()) {
    entry.image = RasterizePicture(picture, context, transformation_matrix,
                                   dst_color_space, checkerboard_images_);
  }
  return true;
}

RasterCacheResult RasterCache::Get(const SkPicture& picture,
                                   const SkMatrix& ctm) const {
  PictureRasterCacheKey cache_key(picture.uniqueID(), ctm);
  auto it = picture_cache_.find(cache_key);
  return it == picture_cache_.end() ? RasterCacheResult() : it->second.image;
}

RasterCacheResult RasterCache::Get(std::shared_ptr<Layer> layer,
                                   const SkMatrix& ctm) const {
  LayerRasterCacheKey cache_key(layer, ctm);
  auto it = layer_cache_.find(cache_key);
  return it == layer_cache_.end() ? RasterCacheResult() : it->second.image;
}

void RasterCache::SweepAfterFrame() {
  using PictureCache = PictureRasterCacheKey::Map<Entry>;
  using LayerCache = LayerRasterCacheKey::Map<Entry>;
  SweepOneCacheAfterFrame<PictureCache, PictureCache::iterator>(picture_cache_);
  SweepOneCacheAfterFrame<LayerCache, LayerCache::iterator>(layer_cache_);
}

void RasterCache::Clear() {
  picture_cache_.clear();
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
