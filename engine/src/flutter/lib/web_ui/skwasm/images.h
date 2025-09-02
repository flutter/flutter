// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_IMAGES_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_IMAGES_H_

#include "skwasm_support.h"

#include "flutter/display_list/display_list.h"
#include "third_party/skia/include/core/SkImage.h"

namespace Skwasm {

enum class PixelFormat {
  rgba8888,
  bgra8888,
  rgbaFloat32,
};

extern sk_sp<SkImage> MakeImageFromPicture(flutter::DisplayList* displayList,
                                           int32_t width,
                                           int32_t height);
extern sk_sp<SkImage> MakeImageFromTexture(SkwasmObject textureSource,
                                           int width,
                                           int height,
                                           Skwasm::Surface* surface);
extern sk_sp<SkImage> MakeImageFromPixels(SkData* data,
                                          int width,
                                          int height,
                                          PixelFormat pixelFormat,
                                          size_t rowByteCount);

}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_IMAGES_H_
