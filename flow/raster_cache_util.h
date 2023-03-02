// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_UTIL_H_
#define FLUTTER_FLOW_RASTER_CACHE_UTIL_H_

#include "flutter/fml/logging.h"
#include "include/core/SkM44.h"
#include "include/core/SkMatrix.h"
#include "include/core/SkRect.h"

namespace flutter {

struct RasterCacheUtil {
  // The default max number of picture and display list raster caches to be
  // generated per frame. Generating too many caches in one frame may cause jank
  // on that frame. This limit allows us to throttle the cache and distribute
  // the work across multiple frames.
  static constexpr int kDefaultPictureAndDisplayListCacheLimitPerFrame = 3;

  // The ImageFilterLayer might cache the filtered output of this layer
  // if the layer remains stable (if it is not animating for instance).
  // If the ImageFilterLayer is not the same between rendered frames,
  // though, it will cache its children instead and filter their cached
  // output on the fly.
  // Caching just the children saves the time to render them and also
  // avoids a rendering surface switch to draw them.
  // Caching the layer itself avoids all of that and additionally avoids
  // the cost of applying the filter, but can be worse than caching the
  // children if the filter itself is not stable from frame to frame.
  // This constant controls how many times we will Preroll and Paint this
  // same ImageFilterLayer before we consider the layer and filter to be
  // stable enough to switch from caching the children to caching the
  // filtered output of this layer.
  static constexpr int kMinimumRendersBeforeCachingFilterLayer = 3;

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

  static SkRect GetDeviceBounds(const SkRect& rect, const SkMatrix& ctm) {
    SkRect device_rect;
    ctm.mapRect(&device_rect, rect);
    return device_rect;
  }

  static SkRect GetRoundedOutDeviceBounds(const SkRect& rect,
                                          const SkMatrix& ctm) {
    SkRect device_rect;
    ctm.mapRect(&device_rect, rect);
    device_rect.roundOut(&device_rect);
    return device_rect;
  }

  /**
   * @brief Snap the translation components of the matrix to integers.
   *
   * The snapping will only happen if the matrix only has scale and translation
   * transformations. This is used, along with GetRoundedOutDeviceBounds, to
   * ensure that the textures drawn by the raster cache are exactly aligned to
   * physical pixels. Any layers that participate in raster caching must align
   * themselves to physical pixels even when not cached to prevent a change in
   * apparent location if caching is later applied.
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

  /**
   * @brief Snap the translation components of the matrix to integers.
   *
   * The snapping will only happen if the matrix only has scale and translation
   * transformations. This is used, along with GetRoundedOutDeviceBounds, to
   * ensure that the textures drawn by the raster cache are exactly aligned to
   * physical pixels. Any layers that participate in raster caching must align
   * themselves to physical pixels even when not cached to prevent a change in
   * apparent location if caching is later applied.
   *
   * @param ctm the current transformation matrix.
   * @return SkM44 the snapped transformation matrix.
   */
  static SkM44 GetIntegralTransCTM(const SkM44& ctm) {
    // Avoid integral snapping if the matrix has complex transformation to avoid
    // the artifact observed in https://github.com/flutter/flutter/issues/41654.
    if (ctm.rc(0, 1) != 0 || ctm.rc(0, 2) != 0) {
      // X multiplied by either Y or Z
      return ctm;
    }
    if (ctm.rc(1, 0) != 0 || ctm.rc(1, 2) != 0) {
      // Y multiplied by either X or Z
      return ctm;
    }
    // We do not need to worry about the Z row unless the W row
    // has perspective entries...
    if (ctm.rc(3, 0) != 0 || ctm.rc(3, 1) != 0 || ctm.rc(3, 2) != 0 ||
        ctm.rc(3, 3) != 1) {
      // W not identity row, therefore perspective is applied
      return ctm;
    }

    SkM44 result = ctm;
    result.setRC(0, 3, SkScalarRoundToScalar(ctm.rc(0, 3)));
    result.setRC(1, 3, SkScalarRoundToScalar(ctm.rc(1, 3)));
    // No need to worry about Z translation because it has no effect
    // without perspective entries...
    return result;
  }
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_RASTER_CACHE_UTIL_H_
