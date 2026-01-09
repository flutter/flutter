// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_IMAGES_H_
#define FLUTTER_SKWASM_IMAGES_H_

#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/skwasm_support.h"

namespace Skwasm {

enum class PixelFormat {
  rgba8888,
  bgra8888,
  rgbaFloat32,
};

extern sk_sp<flutter::DlImage> MakeImageFromPicture(
    flutter::DisplayList* display_list,
    int32_t width,
    int32_t height);
extern sk_sp<flutter::DlImage> MakeImageFromTexture(SkwasmObject texture_source,
                                                    int width,
                                                    int height,
                                                    Skwasm::Surface* surface);
extern sk_sp<flutter::DlImage> MakeImageFromPixels(SkData* data,
                                                   int width,
                                                   int height,
                                                   PixelFormat pixel_format,
                                                   size_t row_byte_count);

}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_IMAGES_H_
