// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/bitmap_platform_device_skia.h"
#include "skia/ext/platform_canvas.h"

namespace skia {

BitmapPlatformDevice* BitmapPlatformDevice::Create(int width, int height,
                                                   bool is_opaque) {
  SkBitmap bitmap;
  if (bitmap.tryAllocN32Pixels(width, height, is_opaque)) {
    // Follow the logic in SkCanvas::createDevice(), initialize the bitmap if it
    // is not opaque.
    if (!is_opaque)
      bitmap.eraseARGB(0, 0, 0, 0);
    return new BitmapPlatformDevice(bitmap);
  }
  return NULL;
}

BitmapPlatformDevice* BitmapPlatformDevice::Create(int width, int height,
                                                   bool is_opaque,
                                                   uint8_t* data) {
  SkBitmap bitmap;
  bitmap.setInfo(SkImageInfo::MakeN32(width, height,
      is_opaque ? kOpaque_SkAlphaType : kPremul_SkAlphaType));
  if (data)
    bitmap.setPixels(data);
  else if (!bitmap.tryAllocPixels())
    return NULL;

  return new BitmapPlatformDevice(bitmap);
}

BitmapPlatformDevice::BitmapPlatformDevice(const SkBitmap& bitmap)
    : SkBitmapDevice(bitmap) {
  SetPlatformDevice(this, this);
}

BitmapPlatformDevice::~BitmapPlatformDevice() {
}

SkBaseDevice* BitmapPlatformDevice::onCreateDevice(const CreateInfo& info,
                                                   const SkPaint*) {
  SkASSERT(info.fInfo.colorType() == kN32_SkColorType);
  return BitmapPlatformDevice::Create(info.fInfo.width(), info.fInfo.height(),
                                      info.fInfo.isOpaque());
}

PlatformSurface BitmapPlatformDevice::BeginPlatformPaint() {
  // TODO(zhenghao): What should we return? The ptr to the address of the
  // pixels? Maybe this won't be called at all.
  return accessBitmap(true).getPixels();
}

// PlatformCanvas impl

SkCanvas* CreatePlatformCanvas(int width, int height, bool is_opaque,
                               uint8_t* data, OnFailureType failureType) {
  skia::RefPtr<SkBaseDevice> dev = skia::AdoptRef(
      BitmapPlatformDevice::Create(width, height, is_opaque, data));
  return CreateCanvas(dev, failureType);
}

// Port of PlatformBitmap to android
PlatformBitmap::~PlatformBitmap() {
  // Nothing to do.
}

bool PlatformBitmap::Allocate(int width, int height, bool is_opaque) {
  if (!bitmap_.tryAllocN32Pixels(width, height, is_opaque))
    return false;

  surface_ = bitmap_.getPixels();
  return true;
}

}  // namespace skia
