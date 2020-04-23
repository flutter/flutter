// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include <vector>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

RasterCacheResult::RasterCacheResult(sk_sp<SkImage> image,
                                     const SkRect& logical_rect)
    : image_(std::move(image)), logical_rect_(logical_rect) {}

void RasterCacheResult::draw(SkCanvas& canvas, const SkPaint* paint) const {
  TRACE_EVENT0("flutter", "RasterCacheResult::draw");
  SkAutoCanvasRestore auto_restore(&canvas, true);
  SkIRect bounds =
      RasterCache::GetDeviceBounds(logical_rect_, canvas.getTotalMatrix());
  FML_DCHECK(
      std::abs(bounds.size().width() - image_->dimensions().width()) <= 1 &&
      std::abs(bounds.size().height() - image_->dimensions().height()) <= 1);
  canvas.resetMatrix();
  canvas.drawImage(image_, bounds.fLeft, bounds.fTop, paint);
}

RasterCache::RasterCache(size_t access_threshold,
                         size_t picture_cache_limit_per_frame)
    : access_threshold_(access_threshold),
      picture_cache_limit_per_frame_(picture_cache_limit_per_frame),
      checkerboard_images_(false) {}

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
  return picture->approximateOpCount() > 5;
}

/// @note Procedure doesn't copy all closures.
static RasterCacheResult Rasterize(
    GrContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard,
    const SkRect& logical_rect,
    const std::function<void(SkCanvas*)>& draw_function) {
  TRACE_EVENT0("flutter", "RasterCachePopulate");
  SkIRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  const SkImageInfo image_info = SkImageInfo::MakeN32Premul(
      cache_rect.width(), cache_rect.height(), sk_ref_sp(dst_color_space));

  sk_sp<SkSurface> surface =
      context
          ? SkSurface::MakeRenderTarget(context, SkBudgeted::kYes, image_info)
          : SkSurface::MakeRaster(image_info);

  if (!surface) {
    return {};
  }

  SkCanvas* canvas = surface->getCanvas();
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
  return Rasterize(context, ctm, dst_color_space, checkerboard,
                   picture->cullRect(),
                   [=](SkCanvas* canvas) { canvas->drawPicture(picture); });
}

void RasterCache::Prepare(PrerollContext* context,
                          Layer* layer,
                          const SkMatrix& ctm) {
  LayerRasterCacheKey cache_key(layer->unique_id(), ctm);
  Entry& entry = layer_cache_[cache_key];
  entry.access_count++;
  entry.used_this_frame = true;
  if (!entry.image.is_valid()) {
    entry.image = Rasterize(
        context->gr_context, ctm, context->dst_color_space,
        checkerboard_images_, layer->paint_bounds(),
        [layer, context](SkCanvas* canvas) {
          SkISize canvas_size = canvas->getBaseLayerSize();
          SkNWayCanvas internal_nodes_canvas(canvas_size.width(),
                                             canvas_size.height());
          internal_nodes_canvas.addCanvas(canvas);
          Layer::PaintContext paintContext = {
              (SkCanvas*)&internal_nodes_canvas,
              canvas,
              context->gr_context,
              nullptr,
              context->raster_time,
              context->ui_time,
              context->texture_registry,
              context->has_platform_view ? nullptr : context->raster_cache,
              context->checkerboard_offscreen_layers,
              context->frame_physical_depth,
              context->frame_device_pixel_ratio};
          if (layer->needs_painting()) {
            layer->Paint(paintContext);
          }
        });
  }
}

bool RasterCache::Prepare(GrContext* context,
                          SkPicture* picture,
                          const SkMatrix& transformation_matrix,
                          SkColorSpace* dst_color_space,
                          bool is_complex,
                          bool will_change) {
  // Disabling caching when access_threshold is zero is historic behavior.
  if (access_threshold_ == 0) {
    return false;
  }
  if (picture_cached_this_frame_ >= picture_cache_limit_per_frame_) {
    return false;
  }
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

  // Creates an entry, if not present prior.
  Entry& entry = picture_cache_[cache_key];
  if (entry.access_count < access_threshold_) {
    // Frame threshold has not yet been reached.
    return false;
  }

  if (!entry.image.is_valid()) {
    entry.image = RasterizePicture(picture, context, transformation_matrix,
                                   dst_color_space, checkerboard_images_);
    picture_cached_this_frame_++;
  }
  return true;
}

bool RasterCache::Draw(const SkPicture& picture, SkCanvas& canvas) const {
  PictureRasterCacheKey cache_key(picture.uniqueID(), canvas.getTotalMatrix());
  auto it = picture_cache_.find(cache_key);
  if (it == picture_cache_.end()) {
    return false;
  }

  Entry& entry = it->second;
  entry.access_count++;
  entry.used_this_frame = true;

  if (entry.image.is_valid()) {
    entry.image.draw(canvas);
    return true;
  }

  return false;
}

bool RasterCache::Draw(const Layer* layer,
                       SkCanvas& canvas,
                       SkPaint* paint) const {
  LayerRasterCacheKey cache_key(layer->unique_id(), canvas.getTotalMatrix());
  auto it = layer_cache_.find(cache_key);
  if (it == layer_cache_.end()) {
    return false;
  }

  Entry& entry = it->second;
  entry.access_count++;
  entry.used_this_frame = true;

  if (entry.image.is_valid()) {
    entry.image.draw(canvas, paint);
    return true;
  }

  return false;
}

void RasterCache::SweepAfterFrame() {
  SweepOneCacheAfterFrame(picture_cache_);
  SweepOneCacheAfterFrame(layer_cache_);
  picture_cached_this_frame_ = 0;
  TraceStatsToTimeline();
}

void RasterCache::Clear() {
  picture_cache_.clear();
  layer_cache_.clear();
}

size_t RasterCache::GetCachedEntriesCount() const {
  return layer_cache_.size() + picture_cache_.size();
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

  size_t layer_cache_count = 0;
  size_t layer_cache_bytes = 0;
  size_t picture_cache_count = 0;
  size_t picture_cache_bytes = 0;

  for (const auto& item : layer_cache_) {
    const auto dimensions = item.second.image.image_dimensions();
    layer_cache_count++;
    layer_cache_bytes += dimensions.width() * dimensions.height() * 4;
  }

  for (const auto& item : picture_cache_) {
    const auto dimensions = item.second.image.image_dimensions();
    picture_cache_count++;
    picture_cache_bytes += dimensions.width() * dimensions.height() * 4;
  }

  FML_TRACE_COUNTER("flutter", "RasterCache",
                    reinterpret_cast<int64_t>(this),             //
                    "LayerCount", layer_cache_count,             //
                    "LayerMBytes", layer_cache_bytes * 1e-6,     //
                    "PictureCount", picture_cache_count,         //
                    "PictureMBytes", picture_cache_bytes * 1e-6  //
  );

#endif  // !FLUTTER_RELEASE
}

}  // namespace flutter
