// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_SKIA_UTILS_IOS_H_
#define SKIA_EXT_SKIA_UTILS_IOS_H_

#include <CoreGraphics/CoreGraphics.h>
#include <vector>

#include "third_party/skia/include/core/SkBitmap.h"

#ifdef __OBJC__
@class UIImage;
@class NSData;
#else
class UIImage;
class NSData;
#endif

namespace gfx {

// Draws a CGImage into an SkBitmap of the given size.
SK_API SkBitmap CGImageToSkBitmap(CGImageRef image,
                                  CGSize size,
                                  bool is_opaque);

// Given an SkBitmap and a color space, return an autoreleased UIImage.
SK_API UIImage* SkBitmapToUIImageWithColorSpace(const SkBitmap& skia_bitmap,
                                                CGFloat scale,
                                                CGColorSpaceRef color_space);

// Decodes all image representations inside the data into a vector of SkBitmaps.
// Returns a vector of all the successfully decoded representations or an empty
// vector if none can be decoded.
SK_API std::vector<SkBitmap> ImageDataToSkBitmaps(NSData* image_data);

}  // namespace gfx

#endif  // SKIA_EXT_SKIA_UTILS_IOS_H_
