// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TEXTURE_IMAGE_H_
#define FLOW_TEXTURE_IMAGE_H_

#include "base/macros.h"
#include "third_party/skia/include/core/SkImage.h"

namespace flow {

enum class TextureImageFormat {
  Grey,
  GreyAlpha,
  RGB,
  RGBA,
};

enum class TextureImageDataFormat {
  UnsignedByte,
  UnsignedShort565,
};

sk_sp<SkImage> TextureImageCreate(GrContext* context,
                                  TextureImageFormat format,
                                  const SkISize& size,
                                  TextureImageDataFormat dataFormat,
                                  const uint8_t* data);

}  // namespace flow

#endif  // FLOW_TEXTURE_IMAGE_H_
