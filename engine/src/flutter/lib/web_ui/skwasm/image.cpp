// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"

#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPicture.h"

using namespace SkImages;

enum class PixelFormat {
  rgba8888,
  bgra8888,
  rgbaFloat32,
};

SkColorType colorTypeForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::rgba8888:
      return SkColorType::kRGBA_8888_SkColorType;
    case PixelFormat::bgra8888:
      return SkColorType::kBGRA_8888_SkColorType;
    case PixelFormat::rgbaFloat32:
      return SkColorType::kRGBA_F32_SkColorType;
  }
}

SkAlphaType alphaTypeForPixelFormat(PixelFormat format) {
  switch (format) {
    case PixelFormat::rgba8888:
    case PixelFormat::bgra8888:
      return SkAlphaType::kPremul_SkAlphaType;
    case PixelFormat::rgbaFloat32:
      return SkAlphaType::kUnpremul_SkAlphaType;
  }
}

SKWASM_EXPORT SkImage* image_createFromPicture(SkPicture* picture,
                                               int32_t width,
                                               int32_t height) {
  picture->ref();
  return DeferredFromPicture(sk_sp<SkPicture>(picture), {width, height},
                             nullptr, nullptr, BitDepth::kU8,
                             SkColorSpace::MakeSRGB())
      .release();
}

SKWASM_EXPORT SkImage* image_createFromPixels(SkData* data,
                                              int width,
                                              int height,
                                              PixelFormat pixelFormat,
                                              size_t rowByteCount) {
  data->ref();
  return SkImages::RasterFromData(
             SkImageInfo::Make(width, height,
                               colorTypeForPixelFormat(pixelFormat),
                               alphaTypeForPixelFormat(pixelFormat),
                               SkColorSpace::MakeSRGB()),
             sk_sp(data), rowByteCount)
      .release();
}

SKWASM_EXPORT void image_dispose(SkImage* image) {
  image->unref();
}

SKWASM_EXPORT int image_getWidth(SkImage* image) {
  return image->width();
}

SKWASM_EXPORT int image_getHeight(SkImage* image) {
  return image->height();
}
