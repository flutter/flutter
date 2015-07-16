// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/platform_device.h"

namespace skia {

PlatformSurface PlatformDevice::BeginPlatformPaint() {
  return NULL;
}

void PlatformDevice::EndPlatformPaint() {
  // We don't need to do anything on Linux here.
}

}  // namespace skia
