// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_IMAGE_OPERATIONS_H_
#define SKIA_EXT_IMAGE_OPERATIONS_H_

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkTypes.h"

struct SkIRect;

namespace skia {

class SK_API ImageOperations {
 public:
  enum ResizeMethod {
    //
    // Quality Methods
    //
    // Those enumeration values express a desired quality/speed tradeoff.
    // They are translated into an algorithm-specific method that depends
    // on the capabilities (CPU, GPU) of the underlying platform.
    // It is possible for all three methods to be mapped to the same
    // algorithm on a given platform.

    // Good quality resizing. Fastest resizing with acceptable visual quality.
    // This is typically intended for use during interactive layouts
    // where slower platforms may want to trade image quality for large
    // increase in resizing performance.
    //
    // For example the resizing implementation may devolve to linear
    // filtering if this enables GPU acceleration to be used.
    //
    // Note that the underlying resizing method may be determined
    // on the fly based on the parameters for a given resize call.
    // For example an implementation using a GPU-based linear filter
    // in the common case may still use a higher-quality software-based
    // filter in cases where using the GPU would actually be slower - due
    // to too much latency - or impossible - due to image format or size
    // constraints.
    RESIZE_GOOD,

    // Medium quality resizing. Close to high quality resizing (better
    // than linear interpolation) with potentially some quality being
    // traded-off for additional speed compared to RESIZE_BEST.
    //
    // This is intended, for example, for generation of large thumbnails
    // (hundreds of pixels in each dimension) from large sources, where
    // a linear filter would produce too many artifacts but where
    // a RESIZE_HIGH might be too costly time-wise.
    RESIZE_BETTER,

    // High quality resizing. The algorithm is picked to favor image quality.
    RESIZE_BEST,

    //
    // Algorithm-specific enumerations
    //

    // Box filter. This is a weighted average of all of the pixels touching
    // the destination pixel. For enlargement, this is nearest neighbor.
    //
    // You probably don't want this, it is here for testing since it is easy to
    // compute. Use RESIZE_LANCZOS3 instead.
    RESIZE_BOX,

    // 1-cycle Hamming filter. This is tall is the middle and falls off towards
    // the window edges but without going to 0. This is about 40% faster than
    // a 2-cycle Lanczos.
    RESIZE_HAMMING1,

    // 2-cycle Lanczos filter. This is tall in the middle, goes negative on
    // each side, then returns to zero. Does not provide as good a frequency
    // response as a 3-cycle Lanczos but is roughly 30% faster.
    RESIZE_LANCZOS2,

    // 3-cycle Lanczos filter. This is tall in the middle, goes negative on
    // each side, then oscillates 2 more times. It gives nice sharp edges.
    RESIZE_LANCZOS3,

    // enum aliases for first and last methods by algorithm or by quality.
    RESIZE_FIRST_QUALITY_METHOD = RESIZE_GOOD,
    RESIZE_LAST_QUALITY_METHOD = RESIZE_BEST,
    RESIZE_FIRST_ALGORITHM_METHOD = RESIZE_BOX,
    RESIZE_LAST_ALGORITHM_METHOD = RESIZE_LANCZOS3,
  };

  // Resizes the given source bitmap using the specified resize method, so that
  // the entire image is (dest_size) big. The dest_subset is the rectangle in
  // this destination image that should actually be returned.
  //
  // The output image will be (dest_subset.width(), dest_subset.height()). This
  // will save work if you do not need the entire bitmap.
  //
  // The destination subset must be smaller than the destination image.
  static SkBitmap Resize(const SkBitmap& source,
                         ResizeMethod method,
                         int dest_width, int dest_height,
                         const SkIRect& dest_subset,
                         SkBitmap::Allocator* allocator = NULL);

  // Alternate version for resizing and returning the entire bitmap rather than
  // a subset.
  static SkBitmap Resize(const SkBitmap& source,
                         ResizeMethod method,
                         int dest_width, int dest_height,
                         SkBitmap::Allocator* allocator = NULL);

 private:
  ImageOperations();  // Class for scoping only.
};

}  // namespace skia

#endif  // SKIA_EXT_IMAGE_OPERATIONS_H_
