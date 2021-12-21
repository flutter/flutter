// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_H_
#define FLUTTER_FLOW_RASTER_CACHE_H_

#include <memory>
#include <unordered_map>

#include "flutter/display_list/display_list.h"
#include "flutter/flow/raster_cache_key.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

class RasterCacheResult {
 public:
  RasterCacheResult(sk_sp<SkImage> image,
                    const SkRect& logical_rect,
                    const char* type);

  virtual ~RasterCacheResult() = default;

  virtual void draw(SkCanvas& canvas, const SkPaint* paint) const;

  virtual SkISize image_dimensions() const {
    return image_ ? image_->dimensions() : SkISize::Make(0, 0);
  };

  virtual int64_t image_bytes() const {
    return image_ ? image_->imageInfo().computeMinByteSize() : 0;
  };

 private:
  sk_sp<SkImage> image_;
  SkRect logical_rect_;
  fml::tracing::TraceFlow flow_;
};

struct PrerollContext;

struct RasterCacheMetrics {
  /**
   * The number of cache entries with images evicted in this frame.
   */
  size_t eviction_count = 0;

  /**
   * The size of all of the images evicted in this frame.
   */
  size_t eviction_bytes = 0;

  /**
   * The number of cache entries with images used in this frame.
   */
  size_t in_use_count = 0;

  /**
   * The size of all of the images used in this frame.
   */
  size_t in_use_bytes = 0;

  /**
   * The total cache entries that had images during this frame whether
   * they were used in the frame or held memory during the frame and then
   * were evicted after it ended.
   */
  size_t total_count() const { return in_use_count + eviction_count; }

  /**
   * The size of all of the cached images during this frame whether
   * they were used in the frame or held memory during the frame and then
   * were evicted after it ended.
   */
  size_t total_bytes() const { return in_use_bytes + eviction_bytes; }
};

class RasterCache {
 public:
  // The default max number of picture and display list raster caches to be
  // generated per frame. Generating too many caches in one frame may cause jank
  // on that frame. This limit allows us to throttle the cache and distribute
  // the work across multiple frames.
  static constexpr int kDefaultPictureAndDispLayListCacheLimitPerFrame = 3;

  explicit RasterCache(size_t access_threshold = 3,
                       size_t picture_and_display_list_cache_limit_per_frame =
                           kDefaultPictureAndDispLayListCacheLimitPerFrame);

  virtual ~RasterCache() = default;

  /**
   * @brief Rasterize a picture object and produce a RasterCacheResult
   * to be stored in the cache.
   *
   * @param picture the SkPicture object to be cached.
   * @param context the GrDirectContext used for rendering.
   * @param ctm the transformation matrix used for rendering.
   * @param dst_color_space the destination color space that the cached
   *        rendering will be drawn into
   * @param checkerboard a flag indicating whether or not a checkerboard
   *        pattern should be rendered into the cached image for debug
   *        analysis
   * @return a RasterCacheResult that can draw the rendered picture into
   *         the destination using a simple image blit
   */
  virtual std::unique_ptr<RasterCacheResult> RasterizePicture(
      SkPicture* picture,
      GrDirectContext* context,
      const SkMatrix& ctm,
      SkColorSpace* dst_color_space,
      bool checkerboard) const;
  virtual std::unique_ptr<RasterCacheResult> RasterizeDisplayList(
      DisplayList* display_list,
      GrDirectContext* context,
      const SkMatrix& ctm,
      SkColorSpace* dst_color_space,
      bool checkerboard) const;

  /**
   * @brief Rasterize an engine Layer and produce a RasterCacheResult
   * to be stored in the cache.
   *
   * @param context the PrerollContext containing important information
   *        needed for rendering a layer.
   * @param layer the Layer object to be cached.
   * @param ctm the transformation matrix used for rendering.
   * @param checkerboard a flag indicating whether or not a checkerboard
   *        pattern should be rendered into the cached image for debug
   *        analysis
   * @return a RasterCacheResult that can draw the rendered layer into
   *         the destination using a simple image blit
   */
  virtual std::unique_ptr<RasterCacheResult> RasterizeLayer(
      PrerollContext* context,
      Layer* layer,
      const SkMatrix& ctm,
      bool checkerboard) const;

  static SkIRect GetDeviceBounds(const SkRect& rect, const SkMatrix& ctm) {
    SkRect device_rect;
    ctm.mapRect(&device_rect, rect);
    SkIRect bounds;
    device_rect.roundOut(&bounds);
    return bounds;
  }

  /**
   * @brief Snap the translation components of the matrix to integers.
   *
   * The snapping will only happen if the matrix only has scale and translation
   * transformations.
   *
   * @param ctm the current transformation matrix.
   * @return SkMatrix the snapped transformation matrix.
   */
  static SkMatrix GetIntegralTransCTM(const SkMatrix& ctm) {
    // Avoid integral snapping if the matrix has complex transformation to avoid
    // the artifact observed in https://github.com/flutter/flutter/issues/41654.
    if (!ctm.isScaleTranslate()) {
      return ctm;
    }
    SkMatrix result = ctm;
    result[SkMatrix::kMTransX] = SkScalarRoundToScalar(ctm.getTranslateX());
    result[SkMatrix::kMTransY] = SkScalarRoundToScalar(ctm.getTranslateY());
    return result;
  }

  // Return true if the cache is generated.
  //
  // We may return false and not generate the cache if
  // 1. There are too many pictures to be cached in the current frame.
  //    (See also kDefaultPictureAndDispLayListCacheLimitPerFrame.)
  // 2. The picture is not worth rasterizing
  // 3. The matrix is singular
  // 4. The picture is accessed too few times
  bool Prepare(PrerollContext* context,
               SkPicture* picture,
               bool is_complex,
               bool will_change,
               const SkMatrix& untranslated_matrix,
               const SkPoint& offset = SkPoint());
  bool Prepare(PrerollContext* context,
               DisplayList* display_list,
               bool is_complex,
               bool will_change,
               const SkMatrix& untranslated_matrix,
               const SkPoint& offset = SkPoint());

  // If there is cache entry for this picture, display list or layer, mark it as
  // used for this frame in order to not get evicted. This is needed during
  // partial repaint for layers that are outside of current clip and are culled
  // away.
  void Touch(SkPicture* picture, const SkMatrix& transformation_matrix);
  void Touch(DisplayList* display_list, const SkMatrix& transformation_matrix);
  void Touch(Layer* layer, const SkMatrix& ctm);

  void Prepare(PrerollContext* context, Layer* layer, const SkMatrix& ctm);

  // Find the raster cache for the picture and draw it to the canvas.
  //
  // Return true if it's found and drawn.
  bool Draw(const SkPicture& picture,
            SkCanvas& canvas,
            const SkPaint* paint = nullptr) const;

  // Find the raster cache for the display list and draw it to the canvas.
  //
  // Return true if it's found and drawn.
  bool Draw(const DisplayList& display_list,
            SkCanvas& canvas,
            const SkPaint* paint = nullptr) const;

  // Find the raster cache for the layer and draw it to the canvas.
  //
  // Additional paint can be given to change how the raster cache is drawn
  // (e.g., draw the raster cache with some opacity).
  //
  // Return true if the layer raster cache is found and drawn.
  bool Draw(const Layer* layer,
            SkCanvas& canvas,
            const SkPaint* paint = nullptr) const;

  void PrepareNewFrame();
  void CleanupAfterFrame();

  void Clear();

  void SetCheckboardCacheImages(bool checkerboard);

  const RasterCacheMetrics& picture_metrics() const { return picture_metrics_; }
  const RasterCacheMetrics& layer_metrics() const { return layer_metrics_; }

  size_t GetCachedEntriesCount() const;

  /**
   * Return the number of map entries in the layer cache regardless of whether
   * the entries have been populated with an image.
   */
  size_t GetLayerCachedEntriesCount() const;

  /**
   * Return the number of map entries in the picture caches (SkPicture and
   * DisplayList) regardless of whether the entries have been populated with
   * an image.
   */
  size_t GetPictureCachedEntriesCount() const;

  /**
   * @brief Estimate how much memory is used by picture raster cache entries in
   * bytes, including cache entries in the SkPicture cache and the DisplayList
   * cache.
   *
   * Only SkImage's memory usage is counted as other objects are often much
   * smaller compared to SkImage. SkImageInfo::computeMinByteSize is used to
   * estimate the SkImage memory usage.
   */
  size_t EstimatePictureCacheByteSize() const;

  /**
   * @brief Estimate how much memory is used by layer raster cache entries in
   * bytes.
   *
   * Only SkImage's memory usage is counted as other objects are often much
   * smaller compared to SkImage. SkImageInfo::computeMinByteSize is used to
   * estimate the SkImage memory usage.
   */
  size_t EstimateLayerCacheByteSize() const;

  /**
   * @brief Return the number of frames that a picture must be prepared
   * before it will be cached. If the number is 0, then no picture will
   * ever be cached.
   *
   * If the number is one, then it must be prepared and drawn on 1 frame
   * and it will then be cached on the next frame if it is prepared.
   */
  int access_threshold() const { return access_threshold_; }

 private:
  struct Entry {
    bool used_this_frame = false;
    size_t access_count = 0;
    std::unique_ptr<RasterCacheResult> image;
  };

  template <class Cache>
  static void SweepOneCacheAfterFrame(Cache& cache,
                                      RasterCacheMetrics& metrics) {
    std::vector<typename Cache::iterator> dead;

    for (auto it = cache.begin(); it != cache.end(); ++it) {
      Entry& entry = it->second;
      if (!entry.used_this_frame) {
        dead.push_back(it);
      } else if (entry.image) {
        metrics.in_use_count++;
        metrics.in_use_bytes += entry.image->image_bytes();
      }
      entry.used_this_frame = false;
    }

    for (auto it : dead) {
      if (it->second.image) {
        metrics.eviction_count++;
        metrics.eviction_bytes += it->second.image->image_bytes();
      }
      cache.erase(it);
    }
  }

  bool GenerateNewCacheInThisFrame() const {
    // Disabling caching when access_threshold is zero is historic behavior.
    return access_threshold_ != 0 &&
           picture_cached_this_frame_ + display_list_cached_this_frame_ <
               picture_and_display_list_cache_limit_per_frame_;
  }

  const size_t access_threshold_;
  const size_t picture_and_display_list_cache_limit_per_frame_;
  size_t picture_cached_this_frame_ = 0;
  size_t display_list_cached_this_frame_ = 0;
  RasterCacheMetrics layer_metrics_;
  RasterCacheMetrics picture_metrics_;
  mutable PictureRasterCacheKey::Map<Entry> picture_cache_;
  mutable DisplayListRasterCacheKey::Map<Entry> display_list_cache_;
  mutable LayerRasterCacheKey::Map<Entry> layer_cache_;
  bool checkerboard_images_;

  void TraceStatsToTimeline() const;

  FML_DISALLOW_COPY_AND_ASSIGN(RasterCache);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_RASTER_CACHE_H_
