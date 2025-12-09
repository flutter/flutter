// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/images.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/skwasm_support.h"
#include "flutter/skwasm/surface.h"
#include "flutter/skwasm/wrappers.h"

SKWASM_EXPORT flutter::DlImage* image_createFromPicture(
    flutter::DisplayList* displayList,
    int32_t width,
    int32_t height) {
  Skwasm::liveImageCount++;
  return Skwasm::MakeImageFromPicture(displayList, width, height).release();
}

SKWASM_EXPORT flutter::DlImage* image_createFromPixels(
    SkData* data,
    int width,
    int height,
    Skwasm::PixelFormat pixelFormat,
    size_t rowByteCount) {
  Skwasm::liveImageCount++;
  return Skwasm::MakeImageFromPixels(data, width, height, pixelFormat,
                                     rowByteCount)
      .release();
}

SKWASM_EXPORT flutter::DlImage* image_createFromTextureSource(
    SkwasmObject textureSource,
    int width,
    int height,
    Skwasm::Surface* surface) {
  Skwasm::liveImageCount++;
  return Skwasm::MakeImageFromTexture(textureSource, width, height, surface)
      .release();
}

SKWASM_EXPORT void image_ref(flutter::DlImage* image) {
  Skwasm::liveImageCount++;
  image->ref();
}

SKWASM_EXPORT void image_dispose(flutter::DlImage* image) {
  Skwasm::liveImageCount--;
  image->unref();
}

SKWASM_EXPORT int image_getWidth(flutter::DlImage* image) {
  return image->width();
}

SKWASM_EXPORT int image_getHeight(flutter::DlImage* image) {
  return image->height();
}
