// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/skia_utils_ios.h"

#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

#include "base/ios/ios_util.h"
#include "base/logging.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/macros.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

namespace {

const uint8 kICOHeaderMagic[4] = {0x00, 0x00, 0x01, 0x00};

// Returns whether the data encodes an ico image.
bool EncodesIcoImage(NSData* image_data) {
  if (image_data.length < arraysize(kICOHeaderMagic))
    return false;
  return memcmp(kICOHeaderMagic, image_data.bytes,
                arraysize(kICOHeaderMagic)) == 0;
}

}  // namespace

namespace gfx {

SkBitmap CGImageToSkBitmap(CGImageRef image, CGSize size, bool is_opaque) {
  SkBitmap bitmap;
  if (!image)
    return bitmap;

  if (!bitmap.tryAllocN32Pixels(size.width, size.height, is_opaque))
    return bitmap;

  void* data = bitmap.getPixels();

  // Allocate a bitmap context with 4 components per pixel (BGRA). Apple
  // recommends these flags for improved CG performance.
#define HAS_ARGB_SHIFTS(a, r, g, b) \
            (SK_A32_SHIFT == (a) && SK_R32_SHIFT == (r) \
             && SK_G32_SHIFT == (g) && SK_B32_SHIFT == (b))
#if defined(SK_CPU_LENDIAN) && HAS_ARGB_SHIFTS(24, 16, 8, 0)
  base::ScopedCFTypeRef<CGColorSpaceRef> color_space(
      CGColorSpaceCreateDeviceRGB());
  base::ScopedCFTypeRef<CGContextRef> context(CGBitmapContextCreate(
      data,
      size.width,
      size.height,
      8,
      size.width * 4,
      color_space,
      kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host));
#else
#error We require that Skia's and CoreGraphics's recommended \
       image memory layout match.
#endif
#undef HAS_ARGB_SHIFTS

  DCHECK(context);
  if (!context)
    return bitmap;

  CGRect imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
  CGContextSetBlendMode(context, kCGBlendModeCopy);
  CGContextDrawImage(context, imageRect, image);

  return bitmap;
}

UIImage* SkBitmapToUIImageWithColorSpace(const SkBitmap& skia_bitmap,
                                         CGFloat scale,
                                         CGColorSpaceRef color_space) {
  if (skia_bitmap.isNull())
    return nil;

  // First convert SkBitmap to CGImageRef.
  base::ScopedCFTypeRef<CGImageRef> cg_image(
      SkCreateCGImageRefWithColorspace(skia_bitmap, color_space));

  // Now convert to UIImage.
  return [UIImage imageWithCGImage:cg_image.get()
                             scale:scale
                       orientation:UIImageOrientationUp];
}

std::vector<SkBitmap> ImageDataToSkBitmaps(NSData* image_data) {
  DCHECK(image_data);

  // On iOS 8.1.1 |CGContextDrawImage| crashes when processing images included
  // in .ico files that are 88x88 pixels or larger (http://crbug.com/435068).
  bool skip_images_88x88_or_larger =
      base::ios::IsRunningOnOrLater(8, 1, 1) && EncodesIcoImage(image_data);

  base::ScopedCFTypeRef<CFDictionaryRef> empty_dictionary(
      CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL));
  std::vector<SkBitmap> frames;

  base::ScopedCFTypeRef<CGImageSourceRef> source(
      CGImageSourceCreateWithData((CFDataRef)image_data, empty_dictionary));

  size_t count = CGImageSourceGetCount(source);
  for (size_t index = 0; index < count; ++index) {
    base::ScopedCFTypeRef<CGImageRef> cg_image(
        CGImageSourceCreateImageAtIndex(source, index, empty_dictionary));

    CGSize size = CGSizeMake(CGImageGetWidth(cg_image),
                             CGImageGetHeight(cg_image));
    if (size.width >= 88 && size.height >= 88 && skip_images_88x88_or_larger)
      continue;

    const SkBitmap bitmap = CGImageToSkBitmap(cg_image, size, false);
    if (!bitmap.empty())
      frames.push_back(bitmap);
  }

  DLOG_IF(WARNING, frames.size() != count) << "Only decoded " << frames.size()
      << " frames for " << count << " expected.";
  return frames;
}

}  // namespace gfx
