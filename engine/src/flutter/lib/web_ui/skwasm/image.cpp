// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "live_objects.h"
#include "skwasm_support.h"
#include "surface.h"
#include "wrappers.h"

#include "images.h"

using namespace flutter;

SKWASM_EXPORT DlImage* image_createFromPicture(DisplayList* displayList,
                                               int32_t width,
                                               int32_t height) {
  liveImageCount++;
  return Skwasm::MakeImageFromPicture(displayList, width, height).release();
}

SKWASM_EXPORT DlImage* image_createFromPixels(SkData* data,
                                              int width,
                                              int height,
                                              Skwasm::PixelFormat pixelFormat,
                                              size_t rowByteCount) {
  liveImageCount++;
  return Skwasm::MakeImageFromPixels(data, width, height, pixelFormat,
                                     rowByteCount)
      .release();
}

SKWASM_EXPORT DlImage* image_createFromTextureSource(SkwasmObject textureSource,
                                                     int width,
                                                     int height,
                                                     Skwasm::Surface* surface) {
  liveImageCount++;
  return Skwasm::MakeImageFromTexture(textureSource, width, height, surface)
      .release();
}

SKWASM_EXPORT void image_ref(DlImage* image) {
  liveImageCount++;
  image->ref();
}

SKWASM_EXPORT void image_dispose(DlImage* image) {
  liveImageCount--;
  image->unref();
}

SKWASM_EXPORT int image_getWidth(DlImage* image) {
  return image->width();
}

SKWASM_EXPORT int image_getHeight(DlImage* image) {
  return image->height();
}
