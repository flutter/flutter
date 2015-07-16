// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/platform_device.h"
#include "skia/ext/bitmap_platform_device.h"

#import <ApplicationServices/ApplicationServices.h>
#include "skia/ext/skia_utils_mac.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkTypes.h"
#include "third_party/skia/include/core/SkUtils.h"

namespace skia {

CGContextRef GetBitmapContext(SkBaseDevice* device) {
  PlatformDevice* platform_device = GetPlatformDevice(device);
  if (platform_device)
    return platform_device->GetBitmapContext();

  return NULL;
}

CGContextRef PlatformDevice::BeginPlatformPaint() {
  return GetBitmapContext();
}

void PlatformDevice::EndPlatformPaint() {
  // Flushing will be done in onAccessBitmap.
}

}  // namespace skia
