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
    flutter::DisplayList* display_list,
    int32_t width,
    int32_t height) {
  Skwasm::live_image_count++;
  return Skwasm::MakeImageFromPicture(display_list, width, height).release();
}

SKWASM_EXPORT flutter::DlImage* image_createFromPixels(
    SkData* data,
    int width,
    int height,
    Skwasm::PixelFormat pixel_format,
    size_t row_byte_count) {
  Skwasm::live_image_count++;
  return Skwasm::MakeImageFromPixels(data, width, height, pixel_format,
                                     row_byte_count)
      .release();
}

SKWASM_EXPORT flutter::DlImage* image_createFromTextureSource(
    SkwasmObject texture_source,
    int width,
    int height,
    Skwasm::Surface* surface) {
  Skwasm::live_image_count++;
  return Skwasm::MakeImageFromTexture(texture_source, width, height, surface)
      .release();
}

SKWASM_EXPORT void image_ref(flutter::DlImage* image) {
  Skwasm::live_image_count++;
  image->ref();
}

SKWASM_EXPORT void image_dispose(flutter::DlImage* image) {
  Skwasm::live_image_count--;
  image->unref();
}

SKWASM_EXPORT int image_getWidth(flutter::DlImage* image) {
  return image->width();
}

SKWASM_EXPORT int image_getHeight(flutter::DlImage* image) {
  return image->height();
}
