// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include <vector>

#include "flutter/common/constants.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkCanvas.h"
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
  SkIRect bounds =
      RasterCache::GetDeviceBounds(logical_rect_, canvas.getTotalMatrix());
  FML_DCHECK(
      std::abs(bounds.size().width() - image_->dimensions().width()) <= 1 &&
      std::abs(bounds.size().height() - image_->dimensions().height()) <= 1);
  canvas.resetMatrix();
  flow_.Step();
  canvas.drawImage(image_, bounds.fLeft, bounds.fTop, SkSamplingOptions(),
                   paint);
}

RasterCache::RasterCache(size_t access_threshold,
                         size_t picture_and_display_list_cache_limit_per_frame)
    : access_threshold_(access_threshold),
      picture_and_display_list_cache_limit_per_frame_(
          picture_and_display_list_cache_limit_per_frame),
      checkerboard_images_(false) {}

static bool CanRasterizeRect(const SkRect& cull_rect) {
  if (cull_rect.isEmpty()) {
    // No point in ever rasterizing an empty display list.
    return false;
  }

  if (!cull_rect.isFinite()) {
    // Cannot attempt to rasterize into an infinitely large surface.
    FML_LOG(INFO) << "Attempted to raster cache non-finite display list";
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

  if (picture == nullptr || !CanRasterizeRect(picture->cullRect())) {
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
  return picture->approximateOpCount(true) > 5;
}

static bool IsDisplayListWorthRasterizing(DisplayList* display_list,
                                          bool will_change,
                                          bool is_complex) {
  if (will_change) {
    // If the display list is going to change in the future, there is no point
    // in doing to extra work to rasterize.
    return false;
  }

  if (display_list == nullptr || !CanRasterizeRect(display_list->bounds())) {
    // No point in deciding whether the display list is worth rasterizing if it
    // cannot be rasterized at all.
    return false;
  }

  if (is_complex) {
    // The caller seems to have extra information about the display list and
    // thinks the display list is always worth rasterizing.
    return true;
  }

  // TODO(abarth): We should find a better heuristic here that lets us avoid
  // wasting memory on trivial layers that are easy to re-rasterize every frame.
  return display_list->op_count(true) > 5;
}

/// @note Procedure doesn't copy all closures.
static std::unique_ptr<RasterCacheResult> Rasterize(
    GrDirectContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard,
    const SkRect& logical_rect,
    const char* type,
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
    return nullptr;
  }

  SkCanvas* canvas = surface->getCanvas();
  canvas->clear(SK_ColorTRANSPARENT);
  canvas->translate(-cache_rect.left(), -cache_rect.top());
  canvas->concat(ctm);
  draw_function(canvas);

  if (checkerboard) {
    DrawCheckerboard(canvas, logical_rect);
  }

  return std::make_unique<RasterCacheResult>(surface->makeImageSnapshot(),
                                             logical_rect, type);
}

std::unique_ptr<RasterCacheResult> RasterCache::RasterizePicture(
    SkPicture* picture,
    GrDirectContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard) const {
  return Rasterize(context, ctm, dst_color_space, checkerboard,
                   picture->cullRect(), "RasterCacheFlow::SkPicture",
                   [=](SkCanvas* canvas) { canvas->drawPicture(picture); });
}

std::unique_ptr<RasterCacheResult> RasterCache::RasterizeDisplayList(
    DisplayList* display_list,
    GrDirectContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard) const {
  return Rasterize(context, ctm, dst_color_space, checkerboard,
                   display_list->bounds(), "RasterCacheFlow::DisplayList",
                   [=](SkCanvas* canvas) { display_list->RenderTo(canvas); });
}

void RasterCache::Prepare(PrerollContext* context,
                          Layer* layer,
                          const SkMatrix& ctm) {
  LayerRasterCacheKey cache_key(layer->unique_id(), ctm);
  Entry& entry = layer_cache_[cache_key];
  entry.access_count++;
  entry.used_this_frame = true;
  if (!entry.image) {
    entry.image = RasterizeLayer(context, layer, ctm, checkerboard_images_);
  }
}

std::unique_ptr<RasterCacheResult> RasterCache::RasterizeLayer(
    PrerollContext* context,
    Layer* layer,
    const SkMatrix& ctm,
    bool checkerboard) const {
  return Rasterize(
      context->gr_context, ctm, context->dst_color_space, checkerboard,
      layer->paint_bounds(), "RasterCacheFlow::Layer",
      [layer, context](SkCanvas* canvas) {
        SkISize canvas_size = canvas->getBaseLayerSize();
        SkNWayCanvas internal_nodes_canvas(canvas_size.width(),
                                           canvas_size.height());
        internal_nodes_canvas.setMatrix(canvas->getTotalMatrix());
        internal_nodes_canvas.addCanvas(canvas);
        Layer::PaintContext paintContext = {
            /* internal_nodes_canvas= */ static_cast<SkCanvas*>(
                &internal_nodes_canvas),
            /* leaf_nodes_canvas= */ canvas,
            /* gr_context= */ context->gr_context,
            /* view_embedder= */ nullptr,
            context->raster_time,
            context->ui_time,
            context->texture_registry,
            context->has_platform_view ? nullptr : context->raster_cache,
            context->checkerboard_offscreen_layers,
            context->frame_device_pixel_ratio};
        if (layer->needs_painting(paintContext)) {
          layer->Paint(paintContext);
        }
      });
}

bool RasterCache::Prepare(PrerollContext* context,
                          SkPicture* picture,
                          bool is_complex,
                          bool will_change,
                          const SkMatrix& untranslated_matrix,
                          const SkPoint& offset) {
  if (!GenerateNewCacheInThisFrame()) {
    return false;
  }

  if (!IsPictureWorthRasterizing(picture, will_change, is_complex)) {
    // We only deal with pictures that are worthy of rasterization.
    return false;
  }

  SkMatrix transformation_matrix = untranslated_matrix;
  transformation_matrix.preTranslate(offset.x(), offset.y());

  if (!transformation_matrix.invert(nullptr)) {
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

  if (!entry.image) {
    // GetIntegralTransCTM effect for matrix which only contains scale,
    // translate, so it won't affect result of matrix decomposition and cache
    // key.
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    transformation_matrix = GetIntegralTransCTM(transformation_matrix);
#endif
    entry.image =
        RasterizePicture(picture, context->gr_context, transformation_matrix,
                         context->dst_color_space, checkerboard_images_);
    picture_cached_this_frame_++;
  }
  return true;
}

bool RasterCache::Prepare(PrerollContext* context,
                          DisplayList* display_list,
                          bool is_complex,
                          bool will_change,
                          const SkMatrix& untranslated_matrix,
                          const SkPoint& offset) {
  if (!GenerateNewCacheInThisFrame()) {
    return false;
  }

  if (!IsDisplayListWorthRasterizing(display_list, will_change, is_complex)) {
    // We only deal with display lists that are worthy of rasterization.
    return false;
  }

  SkMatrix transformation_matrix = untranslated_matrix;
  transformation_matrix.preTranslate(offset.x(), offset.y());

  if (!transformation_matrix.invert(nullptr)) {
    // The matrix was singular. No point in going further.
    return false;
  }

  DisplayListRasterCacheKey cache_key(display_list->unique_id(),
                                      transformation_matrix);

  // Creates an entry, if not present prior.
  Entry& entry = display_list_cache_[cache_key];
  if (entry.access_count < access_threshold_) {
    // Frame threshold has not yet been reached.
    return false;
  }

  if (!entry.image) {
    // GetIntegralTransCTM effect for matrix which only contains scale,
    // translate, so it won't affect result of matrix decomposition and cache
    // key.
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    transformation_matrix = GetIntegralTransCTM(transformation_matrix);
#endif
    entry.image = RasterizeDisplayList(
        display_list, context->gr_context, transformation_matrix,
        context->dst_color_space, checkerboard_images_);
    display_list_cached_this_frame_++;
  }
  return true;
}

void RasterCache::Touch(Layer* layer, const SkMatrix& ctm) {
  LayerRasterCacheKey cache_key(layer->unique_id(), ctm);
  auto it = layer_cache_.find(cache_key);
  if (it != layer_cache_.end()) {
    it->second.used_this_frame = true;
    it->second.access_count++;
  }
}

void RasterCache::Touch(SkPicture* picture,
                        const SkMatrix& transformation_matrix) {
  PictureRasterCacheKey cache_key(picture->uniqueID(), transformation_matrix);
  auto it = picture_cache_.find(cache_key);
  if (it != picture_cache_.end()) {
    it->second.used_this_frame = true;
    it->second.access_count++;
  }
}

void RasterCache::Touch(DisplayList* display_list,
                        const SkMatrix& transformation_matrix) {
  DisplayListRasterCacheKey cache_key(display_list->unique_id(),
                                      transformation_matrix);
  auto it = display_list_cache_.find(cache_key);
  if (it != display_list_cache_.end()) {
    it->second.used_this_frame = true;
    it->second.access_count++;
  }
}

bool RasterCache::Draw(const SkPicture& picture,
                       SkCanvas& canvas,
                       const SkPaint* paint) const {
  PictureRasterCacheKey cache_key(picture.uniqueID(), canvas.getTotalMatrix());
  auto it = picture_cache_.find(cache_key);
  if (it == picture_cache_.end()) {
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

bool RasterCache::Draw(const DisplayList& display_list,
                       SkCanvas& canvas,
                       const SkPaint* paint) const {
  DisplayListRasterCacheKey cache_key(display_list.unique_id(),
                                      canvas.getTotalMatrix());
  auto it = display_list_cache_.find(cache_key);
  if (it == display_list_cache_.end()) {
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

bool RasterCache::Draw(const Layer* layer,
                       SkCanvas& canvas,
                       const SkPaint* paint) const {
  LayerRasterCacheKey cache_key(layer->unique_id(), canvas.getTotalMatrix());
  auto it = layer_cache_.find(cache_key);
  if (it == layer_cache_.end()) {
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
  picture_cached_this_frame_ = 0;
  display_list_cached_this_frame_ = 0;
}

void RasterCache::CleanupAfterFrame() {
  picture_metrics_ = {};
  layer_metrics_ = {};
  {
    TRACE_EVENT0("flutter", "RasterCache::SweepCaches");
    SweepOneCacheAfterFrame(picture_cache_, picture_metrics_);
    SweepOneCacheAfterFrame(display_list_cache_, picture_metrics_);
    SweepOneCacheAfterFrame(layer_cache_, layer_metrics_);
  }
  TraceStatsToTimeline();
}

void RasterCache::Clear() {
  picture_cache_.clear();
  display_list_cache_.clear();
  layer_cache_.clear();
  picture_metrics_ = {};
  layer_metrics_ = {};
}

size_t RasterCache::GetCachedEntriesCount() const {
  return layer_cache_.size() + picture_cache_.size() +
         display_list_cache_.size();
}

size_t RasterCache::GetLayerCachedEntriesCount() const {
  return layer_cache_.size();
}

size_t RasterCache::GetPictureCachedEntriesCount() const {
  return picture_cache_.size() + display_list_cache_.size();
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
  for (const auto& item : layer_cache_) {
    if (item.second.image) {
      layer_cache_bytes += item.second.image->image_bytes();
    }
  }
  return layer_cache_bytes;
}

size_t RasterCache::EstimatePictureCacheByteSize() const {
  size_t picture_cache_bytes = 0;
  for (const auto& item : picture_cache_) {
    if (item.second.image) {
      picture_cache_bytes += item.second.image->image_bytes();
    }
  }
  for (const auto& item : display_list_cache_) {
    if (item.second.image) {
      picture_cache_bytes += item.second.image->image_bytes();
    }
  }
  return picture_cache_bytes;
}

}  // namespace flutter
