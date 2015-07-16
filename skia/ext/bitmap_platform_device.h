// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_BITMAP_PLATFORM_DEVICE_H_
#define SKIA_EXT_BITMAP_PLATFORM_DEVICE_H_

// This file provides an easy way to include the appropriate
// BitmapPlatformDevice header file for your platform.

#if defined(WIN32)
#include "skia/ext/bitmap_platform_device_win.h"
#elif defined(__APPLE__)
#include "skia/ext/bitmap_platform_device_mac.h"
#elif defined(USE_CAIRO)
#include "skia/ext/bitmap_platform_device_cairo.h"
#else
#include "skia/ext/bitmap_platform_device_skia.h"
#endif

namespace skia {
    // Returns true if it is unsafe to attempt to allocate an offscreen buffer
    // given these dimensions.
    inline bool RasterDeviceTooBigToAllocate(int width, int height) {

#ifndef SKIA_EXT_RASTER_DEVICE_ALLOCATION_MAX
#define SKIA_EXT_RASTER_DEVICE_ALLOCATION_MAX    (2 * 256 * 1024 * 1024)
#endif

    int bytesPerPixel = 4;
    int64_t bytes = (int64_t)width * height * bytesPerPixel;
    return bytes > SKIA_EXT_RASTER_DEVICE_ALLOCATION_MAX;
  }
}

#endif  // SKIA_EXT_BITMAP_PLATFORM_DEVICE_H_
