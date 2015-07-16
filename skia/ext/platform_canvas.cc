// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/platform_canvas.h"

#include "skia/ext/bitmap_platform_device.h"
#include "third_party/skia/include/core/SkTypes.h"

namespace skia {

SkBaseDevice* GetTopDevice(const SkCanvas& canvas) {
  return canvas.getTopDevice(true);
}

bool SupportsPlatformPaint(const SkCanvas* canvas) {
  PlatformDevice* platform_device = GetPlatformDevice(GetTopDevice(*canvas));
  return platform_device && platform_device->SupportsPlatformPaint();
}

PlatformSurface BeginPlatformPaint(SkCanvas* canvas) {
  PlatformDevice* platform_device = GetPlatformDevice(GetTopDevice(*canvas));
  if (platform_device)
    return platform_device->BeginPlatformPaint();

  return 0;
}

void EndPlatformPaint(SkCanvas* canvas) {
  PlatformDevice* platform_device = GetPlatformDevice(GetTopDevice(*canvas));
  if (platform_device)
    platform_device->EndPlatformPaint();
}

void MakeOpaque(SkCanvas* canvas, int x, int y, int width, int height) {
  if (width <= 0 || height <= 0)
    return;

  SkRect rect;
  rect.setXYWH(SkIntToScalar(x), SkIntToScalar(y),
               SkIntToScalar(width), SkIntToScalar(height));
  SkPaint paint;
  paint.setColor(SK_ColorBLACK);
  paint.setXfermodeMode(SkXfermode::kDstATop_Mode);
  canvas->drawRect(rect, paint);
}

size_t PlatformCanvasStrideForWidth(unsigned width) {
  return 4 * width;
}

SkCanvas* CreateCanvas(const skia::RefPtr<SkBaseDevice>& device, OnFailureType failureType) {
  if (!device) {
    if (CRASH_ON_FAILURE == failureType)
      SK_CRASH();
    return NULL;
  }
  return new SkCanvas(device.get());
}

PlatformBitmap::PlatformBitmap() : surface_(0), platform_extra_(0) {}

}  // namespace skia
